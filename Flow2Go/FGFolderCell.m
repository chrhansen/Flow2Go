//
//  F2GFolderCell.m
//  Flow2Go
//
//  Created by Christian Hansen on 05/02/13.
//  Copyright (c) 2013 Christian Hansen. All rights reserved.
//

#import "FGFolderCell.h"
#import <QuartzCore/QuartzCore.h>

@implementation FGFolderCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {

    }
    return self;
}

- (void)willMoveToSuperview:(UIView *)newSuperview
{
    [super willMoveToSuperview:newSuperview];
    if (newSuperview) {
        self.topContentView.layer.borderColor = [UIColor whiteColor].CGColor;
        self.topContentView.layer.borderWidth = 0.5f;
        self.topContentView.layer.shadowColor = [UIColor blackColor].CGColor;
        self.topContentView.layer.shadowRadius = 3.0f;
        self.topContentView.layer.shadowOffset = CGSizeMake(0.0f, 2.0f);
        self.topContentView.layer.shadowOpacity = 0.5f;
        self.topContentView.layer.rasterizationScale = [[UIScreen mainScreen] scale];
        self.topContentView.layer.shouldRasterize = YES;

        
        self.nameLabel.layer.shadowOpacity = 0.7;
        self.nameLabel.layer.shadowRadius = 3.0;
        self.nameLabel.layer.shadowColor = [UIColor blackColor].CGColor;
        self.nameLabel.layer.shadowOffset = CGSizeMake(0.0, 0.0);
        self.nameLabel.layer.rasterizationScale = [[UIScreen mainScreen] scale];
        self.nameLabel.layer.shouldRasterize = YES;

        self.dateLabel.layer.shadowOpacity = 0.7;
        self.dateLabel.layer.shadowRadius = 3.0;
        self.dateLabel.layer.shadowColor = [UIColor blackColor].CGColor;
        self.dateLabel.layer.shadowOffset = CGSizeMake(0.0, 0.0);
        self.dateLabel.layer.rasterizationScale = [[UIScreen mainScreen] scale];
        self.dateLabel.layer.shouldRasterize = YES;

        self.countLabel.layer.shadowOpacity = 0.7;
        self.countLabel.layer.shadowRadius = 1.0;
        self.countLabel.layer.shadowColor = [UIColor blackColor].CGColor;
        self.countLabel.layer.shadowOffset = CGSizeMake(0.0, 0.0);
        self.countLabel.layer.rasterizationScale = [[UIScreen mainScreen] scale];
        self.countLabel.layer.shouldRasterize = YES;
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
