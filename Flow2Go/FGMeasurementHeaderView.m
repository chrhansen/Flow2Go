//
//  FGMeasurementHeaderView.m
//  Flow2Go
//
//  Created by Christian Hansen on 06/03/13.
//  Copyright (c) 2013 Christian Hansen. All rights reserved.
//

#import "FGMeasurementHeaderView.h"
#import <QuartzCore/QuartzCore.h>
@implementation FGMeasurementHeaderView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}


- (void)willMoveToSuperview:(UIView *)newSuperview
{
    [super willMoveToSuperview:newSuperview];
//    self.titleLabel.layer.shadowColor = [UIColor blackColor].CGColor;
//    self.titleLabel.layer.shadowRadius = 3.0f;
//    self.titleLabel.layer.shadowOffset = CGSizeMake(0.0f, 2.0f);
//    self.titleLabel.layer.shadowOpacity = 0.5f;
//    self.titleLabel.layer.rasterizationScale = [[UIScreen mainScreen] scale];
//    self.titleLabel.layer.shouldRasterize = YES;

}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
