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

- (void)willMoveToSuperview:(UIView *)newSuperview
{
    [super willMoveToSuperview:newSuperview];
    if (newSuperview) {
        self.measurementImageView.layer.shadowRadius = 3.0f;
        self.measurementImageView.layer.shadowOffset = CGSizeMake(0.0f, 2.0f);
        self.measurementImageView.layer.shadowOpacity = 0.5f;
        
        self.thumbImageView.layer.borderColor = [UIColor whiteColor].CGColor;
        self.thumbImageView.layer.borderWidth = 0.5f;
        self.thumbImageView.layer.shadowRadius = 1.0f;
        self.thumbImageView.layer.shadowOffset = CGSizeMake(0.0f, 0.0f);
        self.thumbImageView.layer.shadowOpacity = 0.8f;
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    [self.measurementImageView.layer setShadowPath:[[UIBezierPath bezierPathWithRect:CGRectMake(0, 0, 210.0f, 86.0f)] CGPath]];
    [self.thumbImageView.layer setShadowPath:[[UIBezierPath bezierPathWithRect:CGRectMake(0, 0, 74.0f, 74.0f)] CGPath]];
}


- (void)setState:(FGDownloadState)downloadState isEditing:(BOOL)editing
{
    switch (downloadState) {
        case FGDownloadStateDownloaded:
            self.reloadButton.hidden = YES;
            self.dateLabel.hidden = NO;
            self.infoButton.enabled = YES;
            self.progressView.hidden = YES;
            self.eventCountLabel.hidden = NO;
            break;
            
        case FGDownloadStateDownloading:
            self.reloadButton.hidden = YES;
            self.dateLabel.hidden = YES;
            self.infoButton.enabled = NO;
            self.progressView.hidden = NO;
            self.eventCountLabel.hidden = YES;
            break;
            
        case FGDownloadStateWaiting:
            self.reloadButton.hidden = YES;
            self.dateLabel.hidden = YES;
            self.infoButton.enabled = NO;
            self.progressView.hidden = NO;
            self.eventCountLabel.hidden = YES;
            break;

        case FGDownloadStateFailed:
        case FGDownloadStateUnknown:
            self.reloadButton.hidden = editing ? YES : NO;
            self.dateLabel.hidden = YES;
            self.infoButton.enabled = NO;
            self.progressView.hidden = YES;
            self.eventCountLabel.hidden = YES;
            break;
            
        default:
            break;
    }
}




- (void)setHighlighted:(BOOL)highlighted
{
    self.measurementImageView.backgroundColor = highlighted ? [UIColor lightGrayColor] : [UIColor whiteColor];
}

- (void)setSelected:(BOOL)selected
{
    self.measurementImageView.layer.shadowColor = selected ? [UIColor blueColor].CGColor : [UIColor blackColor].CGColor;
    self.measurementImageView.layer.shadowRadius = selected ? 5.0f : 3.0f;
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
