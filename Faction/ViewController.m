//
//  ViewController.m
//  Faction
//
//  Created by Sahil Gupta on 2015-05-27.
//  Copyright (c) 2015 Sahil Gupta. All rights reserved.
//

#import "ViewController.h"
#import <CoreImage/CoreImage.h>
#import <ImageIO/ImageIO.h>
#import <AssertMacros.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "ImageViewController.h"

@interface ViewController ()
//Private properties
@property (nonatomic) BOOL isUsingFrontFacingCamera;
@property (nonatomic, strong) AVCaptureVideoDataOutput *videoDataOutput;
@property (nonatomic) dispatch_queue_t videoDataOutputQueue;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;
@property (nonatomic, strong) CIDetector *faceDetector;
@property (nonatomic,strong) UIImage *imageTaken;
@property (nonatomic, strong) AVCaptureDevice *activeDevice;
@property (nonatomic) BOOL isFlashActive;


//IB Actions and Outlets
@property (weak, nonatomic) IBOutlet UIButton *smallImageTakenView;
@property (weak, nonatomic) IBOutlet UIButton *shutterButton;
@property (weak, nonatomic) IBOutlet UIImageView *squareOutline;
@property (weak, nonatomic) IBOutlet UIButton *flashButton;
@property (weak, nonatomic) IBOutlet UILabel *messageLabel;


- (IBAction)savePhoto:(UIButton *)sender;
- (IBAction)toggleCamera:(UIButton *)sender;
- (IBAction)takePhoto:(UIButton *)sender;
- (IBAction)toggleFlash:(UIButton *)sender;

@end

@implementation ViewController

AVCaptureSession *session;
AVCaptureStillImageOutput *stillImageOutput;


#pragma mark View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [self setupCapture];
    [self setupOnLoadUI];
    [self setupFaceDetector];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


#pragma mark Capture Setup

- (void) setupCapture {
    
    //Setting up the session for A/V IO.
    session = [[AVCaptureSession alloc] init];
    //session.sessionPreset = AVCaptureSessionPresetPhoto;
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone){
        [session setSessionPreset:AVCaptureSessionPreset640x480];
    } else {
        [session setSessionPreset:AVCaptureSessionPresetPhoto];
    }
    
    //Congifuring the device and device input
    // Select a video device, make an input
    AVCaptureDevice *device;
    
    AVCaptureDevicePosition desiredPosition = AVCaptureDevicePositionFront;
    
    // find the front facing camera
    for (AVCaptureDevice *d in [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo]) {
        if ([d position] == desiredPosition) {
            device = d;
            self.isUsingFrontFacingCamera = YES;
            [self.flashButton setHidden:YES];
            break;
        }
    }
    // fall back to the default camera.
    if( nil == device )
    {
        self.isUsingFrontFacingCamera = NO;
        device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    }
    
    // May enable other features like auto-focusing, auto white balacing etc here.
    if([device isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]){
        NSError *error = nil;
        if([device lockForConfiguration:&error]){
            device.focusMode = AVCaptureFocusModeContinuousAutoFocus;
            [device unlockForConfiguration];
        }
    }
    
    self.activeDevice = device;
    
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
        
        self.videoDataOutputQueue = dispatch_queue_create("VideoDataOutputQueue", DISPATCH_QUEUE_SERIAL);
        [self.videoDataOutput setSampleBufferDelegate:self queue:self.videoDataOutputQueue];
        
        if ( [session canAddOutput:self.videoDataOutput] ){
            [session addOutput:self.videoDataOutput];
        }
        
        
        [[self.videoDataOutput connectionWithMediaType:AVMediaTypeVideo] setEnabled:YES];
        
        
        stillImageOutput = [[AVCaptureStillImageOutput alloc] init]; //Image output allocation
        NSDictionary *outputSettings = [[NSDictionary alloc] initWithObjectsAndKeys:AVVideoCodecJPEG, AVVideoCodecKey, nil]; //configuring the settings for the output
        [stillImageOutput setOutputSettings:outputSettings]; //setting the configured settings.
        
        [session addOutput:stillImageOutput]; //outputting the image.
        
        
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

- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection
{
    // get the image
    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CFDictionaryRef attachments = CMCopyDictionaryOfAttachments(kCFAllocatorDefault, sampleBuffer, kCMAttachmentMode_ShouldPropagate);
    CIImage *ciImage = [[CIImage alloc] initWithCVPixelBuffer:pixelBuffer
                                                      options:(__bridge NSDictionary *)attachments];
    if (attachments) {
        CFRelease(attachments);
    }
    
    // make sure your device orientation is not locked.
    UIDeviceOrientation curDeviceOrientation = [[UIDevice currentDevice] orientation];
    
    NSDictionary *imageOptions = nil;
    
    imageOptions = [NSDictionary dictionaryWithObject:[self exifOrientation:curDeviceOrientation]
                                               forKey:CIDetectorImageOrientation];
    
    NSArray *features = [self.faceDetector featuresInImage:ciImage
                                                   options:imageOptions];
    // get the clean aperture
    // the clean aperture is a rectangle that defines the portion of the encoded pixel dimensions
    // that represents image data valid for display.
    
    CMFormatDescriptionRef fdesc = CMSampleBufferGetFormatDescription(sampleBuffer);
    CGRect clap = CMVideoFormatDescriptionGetCleanAperture(fdesc, false /*originIsTopLeft == false*/);

    dispatch_async(dispatch_get_main_queue(), ^(void) {
        [self showHelperMessage:features forVideoBox:clap orientation:curDeviceOrientation];
    });
}

- (NSNumber *) exifOrientation: (UIDeviceOrientation) orientation
{
    int exifOrientation;
    /* kCGImagePropertyOrientation values
     The intended display orientation of the image. If present, this key is a CFNumber value with the same value as defined
     by the TIFF and EXIF specifications -- see enumeration of integer constants.
     The value specified where the origin (0,0) of the image is located. If not present, a value of 1 is assumed.
     
     used when calling featuresInImage: options: The value for this key is an integer NSNumber from 1..8 as found in kCGImagePropertyOrientation.
     If present, the detection will be done based on that orientation but the coordinates in the returned features will still be based on those of the image. */
    
    enum {
        PHOTOS_EXIF_0ROW_TOP_0COL_LEFT			= 1, //   1  =  0th row is at the top, and 0th column is on the left (THE DEFAULT).
        PHOTOS_EXIF_0ROW_TOP_0COL_RIGHT			= 2, //   2  =  0th row is at the top, and 0th column is on the right.
        PHOTOS_EXIF_0ROW_BOTTOM_0COL_RIGHT      = 3, //   3  =  0th row is at the bottom, and 0th column is on the right.
        PHOTOS_EXIF_0ROW_BOTTOM_0COL_LEFT       = 4, //   4  =  0th row is at the bottom, and 0th column is on the left.
        PHOTOS_EXIF_0ROW_LEFT_0COL_TOP          = 5, //   5  =  0th row is on the left, and 0th column is the top.
        PHOTOS_EXIF_0ROW_RIGHT_0COL_TOP         = 6, //   6  =  0th row is on the right, and 0th column is the top.
        PHOTOS_EXIF_0ROW_RIGHT_0COL_BOTTOM      = 7, //   7  =  0th row is on the right, and 0th column is the bottom.
        PHOTOS_EXIF_0ROW_LEFT_0COL_BOTTOM       = 8  //   8  =  0th row is on the left, and 0th column is the bottom.
    };
    
    switch (orientation) {
        case UIDeviceOrientationPortraitUpsideDown:  // Device oriented vertically, home button on the top
            exifOrientation = PHOTOS_EXIF_0ROW_LEFT_0COL_BOTTOM;
            break;
        case UIDeviceOrientationLandscapeLeft:       // Device oriented horizontally, home button on the right
            if (self.isUsingFrontFacingCamera)
                exifOrientation = PHOTOS_EXIF_0ROW_BOTTOM_0COL_RIGHT;
            else
                exifOrientation = PHOTOS_EXIF_0ROW_TOP_0COL_LEFT;
            break;
        case UIDeviceOrientationLandscapeRight:      // Device oriented horizontally, home button on the left
            if (self.isUsingFrontFacingCamera)
                exifOrientation = PHOTOS_EXIF_0ROW_TOP_0COL_LEFT;
            else
                exifOrientation = PHOTOS_EXIF_0ROW_BOTTOM_0COL_RIGHT;
            break;
        case UIDeviceOrientationPortrait:            // Device oriented vertically, home button on the bottom
        default:
            exifOrientation = PHOTOS_EXIF_0ROW_RIGHT_0COL_TOP;             break;
    }
    return [NSNumber numberWithInt:exifOrientation];
}

// find where the video box is positioned within the preview layer based on the video size and gravity
- (CGRect)videoPreviewBoxForGravity:(NSString *)gravity frameSize:(CGSize)frameSize apertureSize:(CGSize)apertureSize
{
    CGFloat apertureRatio = apertureSize.height / apertureSize.width;
    CGFloat viewRatio = frameSize.width / frameSize.height;
    
    CGSize size = CGSizeZero;
    if ([gravity isEqualToString:AVLayerVideoGravityResizeAspectFill]) {
        if (viewRatio > apertureRatio) {
            size.width = frameSize.width;
            size.height = apertureSize.width * (frameSize.width / apertureSize.height);
        } else {
            size.width = apertureSize.height * (frameSize.height / apertureSize.width);
            size.height = frameSize.height;
        }
    } else if ([gravity isEqualToString:AVLayerVideoGravityResizeAspect]) {
        if (viewRatio > apertureRatio) {
            size.width = apertureSize.height * (frameSize.height / apertureSize.width);
            size.height = frameSize.height;
        } else {
            size.width = frameSize.width;
            size.height = apertureSize.width * (frameSize.width / apertureSize.height);
        }
    } else if ([gravity isEqualToString:AVLayerVideoGravityResize]) {
        size.width = frameSize.width;
        size.height = frameSize.height;
    }
    
    CGRect videoBox;
    videoBox.size = size;
    if (size.width < frameSize.width)
        videoBox.origin.x = (frameSize.width - size.width) / 2;
    else
        videoBox.origin.x = (size.width - frameSize.width) / 2;
    
    if ( size.height < frameSize.height )
        videoBox.origin.y = (frameSize.height - size.height) / 2;
    else
        videoBox.origin.y = (size.height - frameSize.height) / 2;
    
    return videoBox;
}

#pragma mark View helpers



- (void) showHelperMessage : (NSArray *) features forVideoBox:(CGRect)clap orientation:(UIDeviceOrientation)orientation {

    NSUInteger facesDetected = features.count;
    
    [self.shutterButton setEnabled:NO];
    self.messageLabel.textColor = [UIColor redColor];
    if(facesDetected == 0) {
        self.messageLabel.text = @"No faces detected";
    } else if(facesDetected > 1) {
        self.messageLabel.text = @"Only 1 face allowed";
    } else {
        
        for ( CIFaceFeature *ff in features ) {
            
            CGRect faceRect = [ff bounds];
            
            if(faceRect.size.width > 150 && faceRect.size.width < 300) {
                self.messageLabel.textColor = [UIColor greenColor];
                self.messageLabel.text = @"Perfect";
                [self.shutterButton setEnabled:YES];
                [self showFaceTracker:features forVideoBox:clap orientation:orientation];
            }
            else {
                if(faceRect.size.width < 150) {
                    self.messageLabel.text = @"Too far";
                } else {
                    self.messageLabel.text = @"Too close";
                }
            }
        }
    }
}

- (void) showFaceTracker:(NSArray *)features forVideoBox:(CGRect)clap orientation:(UIDeviceOrientation)orientation
{
    [CATransaction begin];
    [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
    
    CGSize parentFrameSize = [self.previewView frame].size;
    NSString *gravity = [self.previewLayer videoGravity];
    CGRect previewBox = [self videoPreviewBoxForGravity:gravity
                                                        frameSize:parentFrameSize
                                                     apertureSize:clap.size];
    
    for ( CIFaceFeature *ff in features ) {
        // find the correct position for the square layer within the previewLayer
        // the feature box originates in the bottom left of the video frame.
        // (Bottom right if mirroring is turned on)
        CGRect faceRect = [ff bounds];
        
        // flip preview width and height
        CGFloat temp = faceRect.size.width;
        faceRect.size.width = faceRect.size.height;
        faceRect.size.height = temp;
        temp = faceRect.origin.x;
        faceRect.origin.x = faceRect.origin.y;
        faceRect.origin.y = temp;
        // scale coordinates so they fit in the preview box, which may be scaled
        CGFloat widthScaleBy = previewBox.size.width / clap.size.height;
        CGFloat heightScaleBy = previewBox.size.height / clap.size.width;
        faceRect.size.width *= widthScaleBy;
        faceRect.size.height *= heightScaleBy;
        faceRect.origin.x *= widthScaleBy;
        faceRect.origin.y *= heightScaleBy;
        
        if ( self.isUsingFrontFacingCamera ) {
            faceRect = CGRectOffset(faceRect, previewBox.origin.x + previewBox.size.width - faceRect.size.width - (faceRect.origin.x * 2), previewBox.origin.y);
        } else {
            faceRect = CGRectOffset(faceRect, previewBox.origin.x, previewBox.origin.y);
        }
        
        faceRect.origin.x -= 100;
        self.squareOutline.frame = faceRect;
    }
    
    [CATransaction commit];
}

- (void) setupOnLoadUI {
    [self.shutterButton setAlpha:.62];
    [self.smallImageTakenView setHidden:YES];
}

#pragma mark utilities

- (void) setupFaceDetector {
    NSDictionary *detectorOptions = [[NSDictionary alloc] initWithObjectsAndKeys:CIDetectorAccuracyLow, CIDetectorAccuracy, nil];
    self.faceDetector = [CIDetector detectorOfType:CIDetectorTypeFace context:nil options:detectorOptions];
}

# pragma mark Orientation Configuration

-(NSUInteger) supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (BOOL) prefersStatusBarHidden {
    return YES;
}



# pragma mark Actions

- (IBAction)takePhoto:(UIButton *)sender {
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
            self.imageTaken = image;
            [self.smallImageTakenView setHidden:NO];
            [self.smallImageTakenView setBackgroundImage:image forState:UIControlStateNormal];
        }
    }];
}

- (IBAction)toggleFlash:(UIButton *)sender {
    
    if([self.activeDevice hasFlash]) {
        if(self.isFlashActive) {
            //Flash is active.
            [self.flashButton setImage:[UIImage imageNamed:@"flash_disabled.png"] forState:UIControlStateNormal];
            if([self.activeDevice isFlashModeSupported:AVCaptureFlashModeOff]){
                NSError *error = nil;
                if([self.activeDevice lockForConfiguration:&error]){
                    [self.activeDevice setFlashMode:AVCaptureFlashModeOff];
                    [self.activeDevice unlockForConfiguration];
                }
            }
            
        } else {
            //Flash is inactive
            [self.flashButton setImage:[UIImage imageNamed:@"flash.png"] forState:UIControlStateNormal];
            
            if([self.activeDevice isFlashModeSupported:AVCaptureFlashModeOn]){
                NSError *error = nil;
                if([self.activeDevice lockForConfiguration:&error]){
                    [self.activeDevice setFlashMode:AVCaptureFlashModeOn];
                    [self.activeDevice unlockForConfiguration];
                }
            }

        }
        self.isFlashActive = !self.isFlashActive;
    }
}


- (IBAction)savePhoto:(UIButton *)sender {
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        [self.smallImageTakenView setHidden:YES];
        UIImageWriteToSavedPhotosAlbum(self.imageTaken, nil, nil, nil);
        [[[UIAlertView alloc] initWithTitle:
          [NSString stringWithFormat:@"Success"]
                                    message:@"Photo saved."
                                   delegate:nil
                          cancelButtonTitle:@"Dismiss"
                          otherButtonTitles:nil] show];
    });
    
}

- (IBAction)toggleCamera:(UIButton *)sender {
    AVCaptureDevicePosition desiredPosition;
    if (self.isUsingFrontFacingCamera) {
        [self.flashButton setHidden:NO];
        desiredPosition = AVCaptureDevicePositionBack;
    }
    else {
        [self.flashButton setHidden:YES];
        desiredPosition = AVCaptureDevicePositionFront;
    }
    
    for (AVCaptureDevice *d in [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo]) {
        if ([d position] == desiredPosition) {
            [[self.previewLayer session] beginConfiguration];
            AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:d error:nil];
            for (AVCaptureInput *oldInput in [[self.previewLayer session] inputs]) {
                [[self.previewLayer session] removeInput:oldInput];
            }
            self.activeDevice = d;
            [[self.previewLayer session] addInput:input];
            [[self.previewLayer session] commitConfiguration];
            break;
        }
    }
    self.isUsingFrontFacingCamera = !self.isUsingFrontFacingCamera;
}


@end
