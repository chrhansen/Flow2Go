//
//  MeasurementCollectionViewController.h
//  Flow2Go
//
//  Created by Christian Hansen on 02/08/12.
//  Copyright (c) 2012 Christian Hansen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AnalysisPresentationProtocol.h"
@class Folder;



@interface MeasurementCollectionViewController : UICollectionViewController <NSFetchedResultsControllerDelegate, UICollectionViewDataSource, UICollectionViewDelegate>

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, strong) Folder *folder;
@property (nonatomic, weak) id<AnalysisPresentationProtocol> delegate;

- (IBAction)infoButtonTapped:(UIButton *)sender;

@end
