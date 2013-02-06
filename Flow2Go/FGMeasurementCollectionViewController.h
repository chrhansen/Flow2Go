//
//  MeasurementCollectionViewController.h
//  Flow2Go
//
//  Created by Christian Hansen on 02/08/12.
//  Copyright (c) 2012 Christian Hansen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MSNavigationPaneViewController.h"

@class FGFolder, FGAnalysisViewController;
@protocol MeasurementCollectionViewControllerDelegate <NSObject>

- (void)measurementCollectionViewControllerDidTapDismiss:(id)sender;

@end

@interface FGMeasurementCollectionViewController : UICollectionViewController <NSFetchedResultsControllerDelegate, UICollectionViewDataSource, UICollectionViewDelegate>

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, strong) FGFolder *folder;
@property (nonatomic, weak) MSNavigationPaneViewController *navigationPaneViewController;
@property (nonatomic, strong) FGAnalysisViewController *analysisViewController;
@property (nonatomic, weak) id<MeasurementCollectionViewControllerDelegate> delegate;

- (IBAction)infoButtonTapped:(UIButton *)sender;

@end
