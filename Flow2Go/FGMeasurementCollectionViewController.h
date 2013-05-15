//
//  FolderCollectionViewController.h
//  Flow2Go
//
//  Created by Christian Hansen on 19/09/12.
//  Copyright (c) 2012 Christian Hansen. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MSNavigationPaneViewController, FGAnalysisViewController;

@interface FGMeasurementCollectionViewController : UICollectionViewController <NSFetchedResultsControllerDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, weak) MSNavigationPaneViewController *navigationPaneViewController;
@property (nonatomic, weak) FGAnalysisViewController *analysisViewController;

@end
