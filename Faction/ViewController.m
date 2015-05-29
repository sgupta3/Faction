//
//  ViewController.m
//  Faction
//
//  Created by Sahil Gupta on 2015-05-27.
//  Copyright (c) 2015 Sahil Gupta. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <CoreImage/CoreImage.h>
#import <ImageIO/ImageIO.h>
#import <AssertMacros.h>
#import <AssetsLibrary/AssetsLibrary.h>

@interface ViewController ()
    @property (nonatomic, strong) AVCaptureVideoDataOutput *videoDataOutput;
    @property (nonatomic) dispatch_queue_t videoDataOutputQueue;
    @property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;


@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupCapture];

}

- (void) viewWillAppear:(BOOL)animated{
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void) setupCapture {
    
    //Setting up the session for A/V IO.
    AVCaptureSession *session = [[AVCaptureSession alloc] init];
    session.sessionPreset = AVCaptureSessionPresetPhoto;
    
    //Congifuring the device and device input
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo]; //Getting the default device which would be the back camera for an iPhone.

    //May enable other features like auto-focusing, auto white balacing etc here.
    if([device isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]){
        NSError *error = nil;
        if([device lockForConfiguration:&error]){
            device.focusMode = AVCaptureFocusModeContinuousAutoFocus;
            [device unlockForConfiguration];
        }
    }
    
    NSError *error = nil;
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
    
    if(!input) {
        NSLog(@"An appropriate device cannot be located");
    }
    
    if(!error){
        
        //Adding the input device to the session.
        if([session canAddInput:input]){
            [session addInput:input];
        }
        
        //Make video data output
        self.videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
        
        
        // we want BGRA, both CoreGraphics and OpenGL work well with 'BGRA'
        NSDictionary *rgbOutputSettings = [NSDictionary dictionaryWithObject:
                                           [NSNumber numberWithInt:kCMPixelFormat_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey];
        
        [self.videoDataOutput setVideoSettings:rgbOutputSettings];
        [self.videoDataOutput setAlwaysDiscardsLateVideoFrames:YES]; //Discard if the data output queue is blocked.
        
        self.videoDataOutputQueue = dispatch_queue_create("VideoDataOutputQueue",DISPATCH_QUEUE_SERIAL);
        [self.videoDataOutput setSampleBufferDelegate:self queue:self.videoDataOutputQueue];
        
        if([session canAddOutput: self.videoDataOutput]) {
            [session addOutput:self.videoDataOutput];
        }
        
        [[self.videoDataOutput connectionWithMediaType:AVMediaTypeVideo] setEnabled:YES];
        
        self.previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:session];
        self.previewLayer.backgroundColor = [[UIColor blackColor] CGColor];
        self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        
        CALayer *rootLayer = self.previewView.layer;
        [rootLayer setMasksToBounds:YES];
        [self.previewLayer setFrame:[rootLayer bounds]];
        [rootLayer addSublayer:self.previewLayer];
        [session startRunning];
    }
    
    session = nil;
    if (error) {
        [[[UIAlertView alloc] initWithTitle:
                                  [NSString stringWithFormat:@"Failed with error %d", (int)[error code]]
                                                            message:[error localizedDescription]
                                                           delegate:nil
                                                  cancelButtonTitle:@"Dismiss"
                                                  otherButtonTitles:nil] show];
    }
}

-(NSUInteger) supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}


@end
