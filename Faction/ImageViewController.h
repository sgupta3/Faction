//
//  ImageViewController.h
//  Faction
//
//  Created by Sahil Gupta on 2015-05-29.
//  Copyright (c) 2015 Sahil Gupta. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ImageViewController : UIViewController
@property(strong,nonatomic) UIImage *imageTaken;
- (IBAction)retakePhoto:(UIButton *)sender;
- (IBAction)savePhoto:(UIButton *)sender;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@end
