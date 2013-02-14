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
        self.plotImageView.layer.shadowColor = [UIColor blackColor].CGColor;
        self.plotImageView.layer.shadowRadius = 3.0f;
        self.plotImageView.layer.shadowOffset = CGSizeMake(0.0f, 2.0f);
        self.plotImageView.layer.shadowOpacity = 0.5f;
        self.plotImageView.layer.rasterizationScale = [[UIScreen mainScreen] scale];
        self.plotImageView.layer.shouldRasterize = YES;
        
        self.nameLabel.layer.shadowOpacity = 0.7;
        self.nameLabel.layer.shadowRadius = 3.0;
        self.nameLabel.layer.shadowColor = [UIColor blackColor].CGColor;
        self.nameLabel.layer.shadowOffset = CGSizeMake(0.0, 0.0);
        self.nameLabel.layer.rasterizationScale = [[UIScreen mainScreen] scale];
        self.nameLabel.layer.shouldRasterize = YES;

        self.countLabel.layer.shadowOpacity = 0.7;
        self.countLabel.layer.shadowRadius = 3.0;
        self.countLabel.layer.shadowColor = [UIColor blackColor].CGColor;
        self.countLabel.layer.shadowOffset = CGSizeMake(0.0, 0.0);
        self.countLabel.layer.rasterizationScale = [[UIScreen mainScreen] scale];
        self.countLabel.layer.shouldRasterize = YES;
        
        self.populationLabel.layer.shadowOpacity = 0.7;
        self.populationLabel.layer.shadowRadius = 3.0;
        self.populationLabel.layer.shadowColor = [UIColor blackColor].CGColor;
        self.populationLabel.layer.shadowOffset = CGSizeMake(0.0, 0.0);
        self.populationLabel.layer.rasterizationScale = [[UIScreen mainScreen] scale];
        self.populationLabel.layer.shouldRasterize = YES;


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
