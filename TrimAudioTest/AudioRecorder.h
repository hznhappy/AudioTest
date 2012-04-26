//
//  AudioRecorder.h
//  TrimAudioTest
//
//  Created by apple on 4/16/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AudioToolbox/AudioFile.h>

#define kNumberBuffers 3          //set the number of audio queue buffers to use

@interface AudioRecorder : NSObject
{
    AudioStreamBasicDescription mDataFormat;  //A structure representing the audio data format write to disk.This format gets used by the audio queue.Field by code.
    AudioQueueRef               mQueue;       //The recording audio queue
    AudioQueueBufferRef         mBuffers[kNumberBuffers];    //An array holding pointers to the audio queue buffers managed by the audio queue
    AudioFileID                 mAudioFile;                  //An audio file object representing the file into which your program records audio data;   
    UInt32                      bufferByteSize;              //The size, in bytes, for each audio queue buffer.   
    SInt64                      mCurrentPacket;             //The packet index for the first packet to be written from the current audio queue buffer.
    bool                        mIsRunning;                 //A boolean value indicating whether or not the audio queue is running;
                                                
}

@property(nonatomic,strong) NSString *url;

-(NSString *)documentPath;

-(void)createAudioFile;

-(void)setAnAudioQueueBufferSize;

-(void)prepareAsetOfAudioQueueBuffers;

-(void)createAudioQueue;

-(void)setUpRecordFormat;

-(void)startRecord;

-(void)stopRecord;

-(void)clearAudioQueue;

-(void)recordAudio;

//The callback function when the audio queue has finished filling an audio queue buffer .
static void HandleInputBuffer(void                                *aqData,             // A custom structure that contains state data for the audio queue like above
                              AudioQueueRef                       inAQ,               // The audio queue that owns this callback
                              AudioQueueBufferRef                 inBuffer,            // The audio queue buffer containing the incoming audio data to record.
                              const AudioTimeStamp                *inStartTime,        /* The sample time of the first sample in the audio queue buffer (not needed 
                                                                                        forsimple recording)*/
                              UInt32                              inNumPackets,        // The number of packet descriptions in the inPacketDesc parameter. A value of 0 indicates CBR data
                              const AudioStreamPacketDescription  *inPacketDesc        /* For compressed audio data formats that require packet descriptions, the packet descriptions           
                                                                                        produced by the encoder for the packets in the buffer.*/
                              );

//A fuction derive the audio queue buffer size
void DeriveBufferSize (
                       AudioQueueRef                audioQueue,                  
                       AudioStreamBasicDescription  ASBDescription,             
                       Float64                      seconds,                     
                       UInt32                       *outBufferSize               
                       );
//Set a magic cookies for audio file 
OSStatus SetMagicCookieForFile (
                                AudioQueueRef inQueue,                                      
                                AudioFileID   inFile                                        
                                );
@end
