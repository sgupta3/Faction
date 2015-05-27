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

AVCaptureSession *session;
AVCaptureStillImageOutput *stillImageOutput;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void) viewWillAppear:(BOOL)animated{
    session = [[AVCaptureSession alloc] init]; //Backend of the video streaming
    [session setSessionPreset:AVCaptureSessionPresetPhoto];
    
    //AVCaptureDevice *inputDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo]; //Setting backfacing camera as input device
    AVCaptureDevice *inputDevice = [self frontFacingCameraIfAvailable]; //setting front camera if available, else back camera.
    NSError *error;
    AVCaptureDeviceInput *deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:inputDevice error:&error]; //For phone to recogonize the input device
    
    if([session canAddInput:deviceInput]){
        [session addInput:deviceInput];
    }
    
    AVCaptureVideoPreviewLayer *previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:session]; //Live feed of the camera - filling the frame
    [previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    CALayer *rootLayer = [[self view] layer];
    [rootLayer setMasksToBounds:YES];
    
    CGRect frame =self.frameForCapture.frame; //create the frame the same UIView in the storyboard.
    [previewLayer setFrame:frame]; //setting the frame
    
    [rootLayer insertSublayer:previewLayer atIndex:0]; //setting the preview layer on top
    
    stillImageOutput = [[AVCaptureStillImageOutput alloc] init]; //Image output allocation
    NSDictionary *outputSettings = [[NSDictionary alloc] initWithObjectsAndKeys:AVVideoCodecJPEG, AVVideoCodecKey, nil]; //configuring the settings for the output
    [stillImageOutput setOutputSettings:outputSettings]; //setting the configured settings.
    
    [session addOutput:stillImageOutput]; //outputting the image.
    [session startRunning]; //Start the live preview
    
    
}

- (IBAction)takePhoto:(id)sender {
    AVCaptureConnection *videoConnection = nil;
    
    //Basic error checking - Checking how many outputs etc.
    for(AVCaptureConnection *connection in stillImageOutput.connections) {
        for(AVCaptureInputPort *port in [connection inputPorts]) {
            if([[port mediaType] isEqual:AVMediaTypeVideo]){
                videoConnection = connection;
                break;
            }
        }
        if(videoConnection){
            break;
        }
    }
    
    //Capture image in the background. Not to interupt live preview etc.
    [stillImageOutput captureStillImageAsynchronouslyFromConnection:videoConnection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
        //As soon as the photo is taken the following code is run.
        if(imageDataSampleBuffer != NULL) {
            NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
            UIImage *image = [UIImage imageWithData:imageData];
            
            self.imageView.image = image;
        }
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(AVCaptureDevice *)frontFacingCameraIfAvailable
{
    NSArray *videoDevices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    AVCaptureDevice *captureDevice = nil;
    for (AVCaptureDevice *device in videoDevices)
    {
        if (device.position == AVCaptureDevicePositionFront)
        {
            captureDevice = device;
            break;
        }
    }
    
    //  couldn't find one on the front, so just get the default video device.
    if ( ! captureDevice)
    {
        captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    }
    
    return captureDevice;
}




@end
