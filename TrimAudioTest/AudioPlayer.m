//
//  AudioPlayer.m
//  TrimAudioTest
//
//  Created by apple on 4/16/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AudioPlayer.h"
static UInt32 gBufferSizeBytes = 0x10000;
@implementation AudioPlayer

@synthesize queue;

// 回调（Callback）函数的实现

static void BufferCallback(void *inUserData, AudioQueueRef inAQ,
                           AudioQueueBufferRef buffer) {
    AudioPlayer* player = (__bridge AudioPlayer*)inUserData;
    [player  audioQueueOutputWithQueue:inAQ queueBuffer:buffer];
}

//初始化方法（为NSObject中定义的初始化方法）

- (id) init {
    for(int i=0; i<NUM_BUFFERS; i++) {
        AudioQueueEnqueueBuffer(queue,buffers[i],0,nil);
    }
    return self;
}

//缓存数据读取方法的实现

- (void) audioQueueOutputWithQueue:(AudioQueueRef)audioQueue
                       queueBuffer:(AudioQueueBufferRef)audioQueueBuffer {
    
    OSStatus status;
    
    // 读取包数据
    UInt32  numBytes;
    
    UInt32  numPackets = numPacketsToRead;
    
    status = AudioFileReadPackets(
                                  audioFile, NO, &numBytes, packetDescs,
                                  packetIndex, &numPackets, audioQueueBuffer->mAudioData);
    // 成功读取时
    if (numPackets > 0) {
        
        //将缓冲的容量设置为与读取的音频数据一样大小（确保内存空间）
        audioQueueBuffer->mAudioDataByteSize = numBytes;
        
        // 完成给队列配置缓存的处理
        status = AudioQueueEnqueueBuffer(
                                         audioQueue, audioQueueBuffer, numPackets, packetDescs);
        
        // 移动包的位置
        packetIndex += numPackets;
    }
}

//音频播放方法的实现

-(void) play:(CFURLRef) path {
    
    UInt32      size, maxPacketSize;
    
    char        *cookie;
    
    int         i;
    
    OSStatus status;
    
    // 打开音频文件
    status = AudioFileOpenURL(path, kAudioFileReadPermission, 0, &audioFile);
    if (status != noErr) {
        // 错误处理
        return;
    }
    // 取得音频数据格式
    size = sizeof(dataFormat);
    AudioFileGetProperty(audioFile, kAudioFilePropertyDataFormat,
                         &size, &dataFormat);
    
    // 创建播放用的音频队列
    AudioQueueNewOutput(&dataFormat, BufferCallback,(__bridge void*)self, nil, nil, 0, &queue);
    
    
    
    //计算单位时间包含的包数
    if (dataFormat.mBytesPerPacket==0 || dataFormat.mFramesPerPacket==0) {
        
        size = sizeof(maxPacketSize);
        AudioFileGetProperty(audioFile,
                             kAudioFilePropertyPacketSizeUpperBound, &size, &maxPacketSize);
        if (maxPacketSize > gBufferSizeBytes) {
            maxPacketSize = gBufferSizeBytes;
            
        }
        
        // 算出单位时间内含有的包数
        numPacketsToRead = gBufferSizeBytes / maxPacketSize;
        packetDescs = malloc(
                             sizeof(AudioStreamPacketDescription) * numPacketsToRead);
    } else {
        numPacketsToRead = gBufferSizeBytes / dataFormat.mBytesPerPacket;
        packetDescs = nil;
    }
    
    //设置Magic Cookie
    AudioFileGetPropertyInfo(audioFile,
                             kAudioFilePropertyMagicCookieData, &size, nil);
    if (size > 0) {
        cookie = malloc(sizeof(char) * size);
        AudioFileGetProperty(audioFile,
                             kAudioFilePropertyMagicCookieData, &size, cookie);
        AudioQueueSetProperty(queue,
                              kAudioQueueProperty_MagicCookie, cookie, size);
        free(cookie);
    }
    
    // 创建并分配缓存空间
    packetIndex = 0;
    
    for (i = 0; i < NUM_BUFFERS; i++) {
        AudioQueueAllocateBuffer(queue, gBufferSizeBytes, &buffers[i]);
        
        //读取包数据
        if ([self readPacketsIntoBuffer:buffers[i]] == 0) {
            break;
        }
    }
    
    Float32 gain = 1.0;
    
    //设置音量
    AudioQueueSetParameter (
                            queue,
                            kAudioQueueParam_Volume,
                            gain
                            );
    
    //队列处理开始，此后系统会自动调用回调（Callback）函数
    AudioQueueStart(queue, nil);

    
    
    //AudioFileID fileID;
   // OSStatus result = AudioFileOpenURL(path, kAudioFileReadPermission, 0, &fileID);
    UInt64 outDataSize = 0;
    UInt32 thePropSize = sizeof(UInt64);
   status = AudioFileGetProperty(audioFile, kAudioFilePropertyEstimatedDuration, &thePropSize, &outDataSize);
    //AudioFileClose(fileID);
}

- (UInt32)readPacketsIntoBuffer:(AudioQueueBufferRef)buffer {
    
    UInt32      numBytes, numPackets;
    
    // 从文件中接受包数据并保存到缓存(buffer)中
    numPackets = numPacketsToRead;
    
    AudioFileReadPackets(audioFile, NO, &numBytes, packetDescs,
                         packetIndex, &numPackets, buffer->mAudioData);
    
    if (numPackets > 0) {
        buffer->mAudioDataByteSize = numBytes;
        AudioQueueEnqueueBuffer(queue, buffer,
                                (packetDescs ? numPackets : 0), packetDescs);
        packetIndex += numPackets;
    }
    return numPackets;
}

@end
