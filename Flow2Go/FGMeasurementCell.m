//
//  FGMeasurementCell.m
//  Flow2Go
//
//  Created by Christian Hansen on 08/02/13.
//  Copyright (c) 2013 Christian Hansen. All rights reserved.
//

#import "FGMeasurementCell.h"
#import <QuartzCore/QuartzCore.h>

@implementation FGMeasurementCell

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
    if (newSuperview) {
        self.measurementImageView.backgroundColor = [UIColor colorWithWhite:1.0f alpha:1.0f];
        self.measurementImageView.layer.borderColor = [UIColor whiteColor].CGColor;
        self.measurementImageView.layer.borderWidth = 0.5f;
        self.measurementImageView.layer.shadowColor = [UIColor blackColor].CGColor;
        self.measurementImageView.layer.shadowRadius = 3.0f;
        self.measurementImageView.layer.shadowOffset = CGSizeMake(0.0f, 2.0f);
        self.measurementImageView.layer.shadowOpacity = 0.5f;
        self.measurementImageView.layer.rasterizationScale = [[UIScreen mainScreen] scale];
        self.measurementImageView.layer.shouldRasterize = YES;
        
        self.fileNameLabel.layer.shadowOpacity = 0.7;
        self.fileNameLabel.layer.shadowRadius = 3.0;
        self.fileNameLabel.layer.shadowColor = [UIColor blackColor].CGColor;
        self.fileNameLabel.layer.shadowOffset = CGSizeMake(0.0, 0.0);
        self.fileNameLabel.layer.rasterizationScale = [[UIScreen mainScreen] scale];
        self.fileNameLabel.layer.shouldRasterize = YES;
    }
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
