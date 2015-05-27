//
//  ViewController.h
//  Faction
//
//  Created by Sahil Gupta on 2015-05-27.
//  Copyright (c) 2015 Sahil Gupta. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController
@property (weak, nonatomic) IBOutlet UIView *frameForCapture;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
- (IBAction)takePhoto:(id)sender;

@end

