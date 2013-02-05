//
//  MeasurementCollectionViewController.h
//  Flow2Go
//
//  Created by Christian Hansen on 02/08/12.
//  Copyright (c) 2012 Christian Hansen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MSNavigationPaneViewController.h"

@class Folder;
@protocol MeasurementCollectionViewControllerDelegate <NSObject>

- (void)measurementCollectionViewControllerDidTapDismiss:(id)sender;

@end

@interface MeasurementCollectionViewController : UICollectionViewController <NSFetchedResultsControllerDelegate, UICollectionViewDataSource, UICollectionViewDelegate>

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, strong) Folder *folder;
@property (nonatomic, weak) MSNavigationPaneViewController *navigationPaneViewController;
@property (nonatomic, weak) id<MeasurementCollectionViewControllerDelegate> delegate;

- (IBAction)infoButtonTapped:(UIButton *)sender;

@end
