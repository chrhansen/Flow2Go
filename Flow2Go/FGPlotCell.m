//
//  F2GPlotCell.m
//  Flow2Go
//
//  Created by Christian Hansen on 05/02/13.
//  Copyright (c) 2013 Christian Hansen. All rights reserved.
//

#import "FGPlotCell.h"
#import <QuartzCore/QuartzCore.h>
@implementation FGPlotCell

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
        self.plotImageView.layer.borderColor = [UIColor whiteColor].CGColor;
        self.plotImageView.layer.borderWidth = 0.5f;
//        self.plotImageView.layer.shadowColor = [UIColor blackColor].CGColor;
        self.plotImageView.layer.shadowRadius = 3.0f;
        self.plotImageView.layer.shadowOffset = CGSizeMake(0.0f, 2.0f);
        self.plotImageView.layer.shadowOpacity = 0.5f;
//        self.plotImageView.layer.rasterizationScale = [[UIScreen mainScreen] scale];
//        self.plotImageView.layer.shouldRasterize = YES;
        
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    [self.plotImageView.layer setShadowPath:[[UIBezierPath bezierPathWithRect:CGRectMake(0, 0, 300.0f, 300.0f)] CGPath]];
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
