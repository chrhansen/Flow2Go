//
//  FolderCollectionViewController.h
//  Flow2Go
//
//  Created by Christian Hansen on 19/09/12.
//  Copyright (c) 2012 Christian Hansen. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FolderCollectionViewController : UICollectionViewController <NSFetchedResultsControllerDelegate, UICollectionViewDataSource, UICollectionViewDelegate>

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;

@end
