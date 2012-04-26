//
//  AudioRecorder.m
//  TrimAudioTest
//
//  Created by apple on 4/16/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AudioRecorder.h"

@implementation AudioRecorder

@synthesize url;
/*Getting the full audio format from audio queue
UInt32 dataFormatSize = sizeof (aqData.mDataFormat);       

AudioQueueGetProperty (                                    
                       aqData.mQueue,                                           
                       kAudioConverterCurrentOutputStreamDescription,          
                       &aqData.mDataFormat,                                     
                       &dataFormatSize                                          
                       );
 

 
 */
-(id)init{
    self = [super init];
    if (self) {
        [self setUpRecordFormat];
        [self createAudioQueue];
        [self setAnAudioQueueBufferSize];
        [self prepareAsetOfAudioQueueBuffers];
        
    }
    return self;
}

-(void)recordAudio{
    [self createAudioFile];
        
    [self startRecord];
}

-(NSString *)documentPath{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *dir = [paths objectAtIndex:0];
    return dir;
}

#pragma mark - Recore audio function
-(void)startRecord{
    mCurrentPacket = 0;                           
    mIsRunning = true;                            
    
    AudioQueueStart (mQueue,NULL);

}

-(void)stopRecord{
    AudioQueueStop (mQueue,true);                                     
            
    mIsRunning = false;
}

-(void)clearAudioQueue{
    AudioQueueDispose (mQueue,true);                               
    AudioFileClose (mAudioFile);   
}
#pragma mark - The audio queue function
//The callback function when the audio queue has finished filling an audio queue buffer .
static void HandleInputBuffer(void *aqData, AudioQueueRef inAQ,AudioQueueBufferRef inBuffer,const AudioTimeStamp *inStartTime,UInt32 inNumPackets,
                              const AudioStreamPacketDescription  *inPacketDesc){
    
    AudioRecorder *pAqData = (__bridge AudioRecorder *)aqData;
    if (inNumPackets == 0 &&                                             
        pAqData->mDataFormat.mBytesPerPacket != 0)
        inNumPackets =
        inBuffer->mAudioDataByteSize / pAqData->mDataFormat.mBytesPerPacket;
    
    if (AudioFileWritePackets (                                          
                               pAqData->mAudioFile,
                               false,
                               inBuffer->mAudioDataByteSize,
                               inPacketDesc,
                               pAqData->mCurrentPacket,
                               &inNumPackets,
                               inBuffer->mAudioData
                               ) == noErr) {
        pAqData->mCurrentPacket += inNumPackets;                     
        NSLog(@"The current packet is :%lld",pAqData->mCurrentPacket);
        if (pAqData->mIsRunning == 0)                                        
            return;
        
        AudioQueueEnqueueBuffer (                                            
                                 pAqData->mQueue,
                                 inBuffer,
                                 0,
                                 NULL
                                 );
    }
}

//Set up the buffer size
-(void)setAnAudioQueueBufferSize{
    DeriveBufferSize(mQueue, mDataFormat, 0.5, &bufferByteSize);
}


-(void)prepareAsetOfAudioQueueBuffers{
    for (int i = 0; i < kNumberBuffers; ++i) {          
        AudioQueueAllocateBuffer (                       
                                  mQueue,                               
                                  bufferByteSize,                              
                                  &mBuffers[i]                          
                                  );
        
        AudioQueueEnqueueBuffer (                        
                                 mQueue,                               
                                 mBuffers[i],                          
                                 0,                                           
                                 NULL                                         
                                 );
    }
}

-(void)createAudioFile{
    NSString *path = [[self documentPath] stringByAppendingPathComponent:[[NSDate date]description]];
    self.url = nil;
    self.url = path;
    NSURL *urls = [NSURL URLWithString:path];
    AudioFileTypeID fileType = kAudioFileAIFFType;
    CFURLRef audioFileURL = (__bridge_retained CFURLRef) urls;
//    CFURLCreateFromFileSystemRepresentation (            
//                                             NULL,                                            
//                                             (__bridge const UInt8 *) filePath,                        
//                                             strlen (filePath),                               
//                                             false                                            
//                                             );
    
    AudioFileCreateWithURL (                                 
                            audioFileURL,                                        
                            fileType,                                            
                            &mDataFormat,                                 
                            kAudioFileFlags_EraseFile,                           
                            &mAudioFile                                   
                            );
    //CFRelease(audioFileURL);
}

-(void)createAudioQueue{
    AudioQueueNewInput(&mDataFormat, HandleInputBuffer, (__bridge void*)self, NULL, kCFRunLoopCommonModes, 0, &mQueue);

}


-(void)setUpRecordFormat{
    mDataFormat.mFormatID = kAudioFormatLinearPCM;
    mDataFormat.mSampleRate = 44100.0;
    mDataFormat.mChannelsPerFrame = 2;
    mDataFormat.mBitsPerChannel = 
    mDataFormat.mBytesPerPacket = 
    mDataFormat.mBytesPerFrame = 
    mDataFormat.mChannelsPerFrame * sizeof (SInt16);
    mDataFormat.mFramesPerPacket = 1;                     
    
    mDataFormat.mFormatFlags =                            
    kLinearPCMFormatFlagIsBigEndian
    | kLinearPCMFormatFlagIsSignedInteger
    | kLinearPCMFormatFlagIsPacked;
    
    
}


//Derive audio queue buffer size
void DeriveBufferSize (
                       AudioQueueRef                audioQueue,                  
                       AudioStreamBasicDescription  ASBDescription,             
                       Float64                      seconds,                     
                       UInt32                       *outBufferSize              
                       ) {
    static const int maxBufferSize = 0x50000;        //320kb         
    
    int maxPacketSize = ASBDescription.mBytesPerPacket;       
    if (maxPacketSize == 0) {                                 
        UInt32 maxVBRPacketSize = sizeof(maxPacketSize);
        AudioQueueGetProperty (
                               audioQueue,
                               kAudioConverterPropertyMaximumOutputPacketSize,
                               &maxPacketSize,
                               &maxVBRPacketSize
                               );
    }
    
    Float64 numBytesForTime =
    ASBDescription.mSampleRate * maxPacketSize * seconds; 
    *outBufferSize =(UInt32)(numBytesForTime < maxBufferSize ?numBytesForTime : maxBufferSize);                     
}

//Set a magic cookie for an audio file 
OSStatus SetMagicCookieForFile (
                                AudioQueueRef inQueue,                                      
                                AudioFileID   inFile                                        
                                ) {
    OSStatus result = noErr;                                    
    UInt32 cookieSize;                                          
    
    if (
        AudioQueueGetPropertySize (                         
                                   inQueue,
                                   kAudioQueueProperty_MagicCookie,
                                   &cookieSize
                                   ) == noErr
        ) {
        char* magicCookie =
        (char *) malloc (cookieSize);                       
        if (
            AudioQueueGetProperty (                         
                                   inQueue,
                                   kAudioQueueProperty_MagicCookie,
                                   magicCookie,
                                   &cookieSize
                                   ) == noErr
            )
            result =    AudioFileSetProperty (                  
                                              inFile,
                                              kAudioFilePropertyMagicCookieData,
                                              cookieSize,
                                              magicCookie
                                              );
        free (magicCookie);                                     
    }
    return result;                                             
}
@end
