//
//  FactionUILabel.m
//  Faction
//
//  Created by Sahil Gupta on 2015-06-01.
//  Copyright (c) 2015 Sahil Gupta. All rights reserved.
//

#import "FactionUILabel.h"

@implementation FactionUILabel

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/
- (void)drawTextInRect:(CGRect)rect {
    UIEdgeInsets insets = {0, 5, 0, 5};
    [super drawTextInRect:UIEdgeInsetsInsetRect(rect, insets)];
}

@end
