//
//  FGMeasurementCell.h
//  Flow2Go
//
//  Created by Christian Hansen on 08/02/13.
//  Copyright (c) 2013 Christian Hansen. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FGMeasurementCell : UICollectionViewCell

- (void)setState:(FGDownloadState)downloadState isEditing:(BOOL)editing;

@property (weak, nonatomic) IBOutlet UILabel *fileNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *eventCountLabel;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (weak, nonatomic) IBOutlet UIButton *infoButton;
@property (weak, nonatomic) IBOutlet UIImageView *measurementImageView;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
@property (weak, nonatomic) IBOutlet UIImageView *checkMarkImageView;
@property (weak, nonatomic) IBOutlet UIImageView *thumbImageView;
@property (weak, nonatomic) IBOutlet UIButton *reloadButton;

@end
