//
//  ViewController.m
//  TrimAudioTest
//
//  Created by apple on 4/19/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

//@implementation UIToolbar (CustomImage)
//- (void)drawRect:(CGRect)rect {
//    UIImage *image = [UIImage imageNamed: @"BottomBar.png"];
//    [image drawInRect:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
//}
//@end
@implementation ViewController
@synthesize toolbar;
- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    UIImage *image = [UIImage imageWithContentsOfFile:[[[NSBundle mainBundle]bundlePath]stringByAppendingPathComponent:@"BottomBar.png"]];
    
    UIButton *cusCamera = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    cusCamera.frame = CGRectMake(0, 0, 100, 30);
    [cusCamera setImage:[UIImage imageWithContentsOfFile:[[[NSBundle mainBundle]bundlePath]stringByAppendingPathComponent:@"camera.png"]] forState:UIControlStateNormal];
    
    UIButton *cusAlbum = [UIButton buttonWithType:UIButtonTypeCustom];
    cusAlbum.frame = CGRectMake(0, 0, 35, 35);
    [cusAlbum setImage:[UIImage imageWithContentsOfFile:[[[NSBundle mainBundle]bundlePath]stringByAppendingPathComponent:@"logo.png"]] forState:UIControlStateNormal];

    UIButton *cusSetting = [UIButton buttonWithType:UIButtonTypeCustom];
    cusSetting.frame = CGRectMake(0, 0, 30, 30);
    [cusSetting setImage:[UIImage imageWithContentsOfFile:[[[NSBundle mainBundle]bundlePath]stringByAppendingPathComponent:@"setting.png"]] forState:UIControlStateNormal];
    
    UIBarButtonItem *camera = [[UIBarButtonItem alloc]initWithCustomView:cusCamera];
    UIBarButtonItem *album = [[UIBarButtonItem alloc]initWithCustomView:cusAlbum];
    UIBarButtonItem *setting = [[UIBarButtonItem alloc]initWithCustomView:cusSetting];
    UIBarButtonItem *flex = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
    
    [toolbar setItems:[NSArray arrayWithObjects:album,flex,camera,flex,setting, nil]];
   [self.toolbar setBackgroundImage:image forToolbarPosition:UIToolbarPositionAny barMetrics:UIBarMetricsDefault];
    recorder = [[AudioRecorder alloc]init];
    
}

-(IBAction)showCamera:(id)sender{
    AVCaptureSession *session = [[AVCaptureSession alloc]init];
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    NSError *error = nil;
    AVCaptureDeviceInput *avInput = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
    if (error) {
        NSLog(@"Open camera error:%@",error);
    }
    [session addInput:avInput];
    [session startRunning];

}

-(IBAction)record:(id)sender{
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    [session setActive:YES error:nil];
    if (player.playing) {
        [player stop];
        player = nil;
    }
    [recorder recordAudio];
}
-(IBAction)play:(id)sender{
    if (player.playing) {
        return;
    }
    [recorder stopRecord];
    [recorder clearAudioQueue];
    NSURL *url = [NSURL URLWithString:recorder.url];
    NSError *error = nil;
    player = [[AVAudioPlayer alloc]initWithContentsOfURL:url error:&error];
    [player prepareToPlay];
    [player play];
}
- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    recorder = nil;
    player = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

@end
