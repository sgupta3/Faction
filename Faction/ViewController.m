//
//  ViewController.m
//  Faction
//
//  Created by Sahil Gupta on 2015-05-27.
//  Copyright (c) 2015 Sahil Gupta. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self startSession];

}

- (void) viewWillAppear:(BOOL)animated{
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void) startSession {
    
    //Setting up the session for A/V IO.
    AVCaptureSession *session = [[AVCaptureSession alloc] init];
    session.sessionPreset = AVCaptureSessionPresetPhoto;
    
    //Congifuring the device and device input
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo]; //Getting the default device which would be the back camera for an iPhone.
    
    NSError *error = nil;
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
    
    if(!input) {
        NSLog(@"An appropriate device cannot be located");
    }
    
    //Adding the input device to the session.
    if([session canAddInput:input]){
        [session addInput:input];
    }
    
    //May enable other features like auto-focusing, auto white balacing etc here.
    if([device isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]){
        NSError *error = nil;
        if([device lockForConfiguration:&error]){
            device.focusMode = AVCaptureFocusModeContinuousAutoFocus;
            [device unlockForConfiguration];
        }
    }
    
    
    
    
}





@end
