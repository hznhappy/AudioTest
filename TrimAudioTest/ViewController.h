//
//  ViewController.h
//  TrimAudioTest
//
//  Created by apple on 4/19/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "AudioPlayer.h"
#import "AudioRecorder.h"

@interface ViewController : UIViewController
{
    AudioRecorder *recorder;
    AVAudioPlayer *player;
}

@property (nonatomic , weak)IBOutlet UIToolbar *toolbar;
-(IBAction)showCamera:(id)sender;
-(IBAction)record:(id)sender;
-(IBAction)play:(id)sender;
@end
