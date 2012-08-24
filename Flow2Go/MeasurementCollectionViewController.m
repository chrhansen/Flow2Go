//
//  MeasurementCollectionViewController.m
//  Flow2Go
//
//  Created by Christian Hansen on 02/08/12.
//  Copyright (c) 2012 Christian Hansen. All rights reserved.
//

#import "MeasurementCollectionViewController.h"
#import "Measurement.h"
#import "Cell.h"
#import "PinchLayout.h"
#import "DownloadManager.h"
#import "AnalysisViewController.h"
#import "Analysis.h"

@interface MeasurementCollectionViewController () <DownloadManagerProgressDelegate>
@end

@implementation MeasurementCollectionViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    UIPinchGestureRecognizer* pinchRecognizer = [UIPinchGestureRecognizer.alloc initWithTarget:self
                                                                                        action:@selector(handlePinchGesture:)];
    [self.collectionView addGestureRecognizer:pinchRecognizer];
    [self.collectionView registerClass:Cell.class forCellWithReuseIdentifier:@"Measurement Cell"];
    self.navigationItem.leftBarButtonItem = self.editButtonItem;
    
    DownloadManager.sharedInstance.progressDelegate = self;
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)configureCell:(Cell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    NSManagedObject *object = [self.fetchedResultsController objectAtIndexPath:indexPath];
    cell.label.text = [(Measurement *)object valueForKey:@"filename"];
}


#pragma mark - Download Manager progress delegate
- (void)downloadManager:(DownloadManager *)sender loadProgress:(CGFloat)progress forDestinationPath:(NSString *)destinationPath
{
    Measurement *downloadingMeasurement = [Measurement findFirstByAttribute:@"filepath" withValue:destinationPath];
    NSIndexPath *downloadIndex = [self.fetchedResultsController indexPathForObject:downloadingMeasurement];
    Cell *downloadCell = (Cell *)[self.collectionView cellForItemAtIndexPath:downloadIndex];
    downloadCell.label.text = [NSString stringWithFormat:@"%.2f", progress];
}


#pragma mark - Collection View Data source
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    id <NSFetchedResultsSectionInfo> sectionInfo = self.fetchedResultsController.sections[section];
    return sectionInfo.numberOfObjects;
}


- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    Cell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Measurement Cell"
                                                           forIndexPath:indexPath];
    [self configureCell:cell atIndexPath:indexPath];
    return cell;
}


- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    Measurement *aMeasurement = (Measurement *)[self.fetchedResultsController objectAtIndexPath:indexPath];
    
    UINavigationController *navigationController = [self.storyboard instantiateViewControllerWithIdentifier:@"analysisViewController"];
    AnalysisViewController *analysisViewController = (AnalysisViewController *)navigationController.topViewController;
    
    if (aMeasurement.analyses.lastObject == nil)
    {
        Analysis *analysis = [Analysis createAnalysisForMeasurement:aMeasurement];
        [analysis.managedObjectContext save];
    }
    analysisViewController.analysis = aMeasurement.analyses.lastObject;
    
    [self presentViewController:navigationController animated:YES completion:nil];
}


#pragma mark - Fetched results controller

- (NSFetchedResultsController *)fetchedResultsController
{
    if (_fetchedResultsController != nil) {
        return _fetchedResultsController;
    }
    
    NSFetchRequest *fetchRequest = [NSFetchRequest.alloc init];
    fetchRequest.entity = [NSEntityDescription entityForName:@"Measurement"
                                      inManagedObjectContext:[NSManagedObjectContext MR_defaultContext]];
    
    // Set the batch size to a suitable number.
    fetchRequest.fetchBatchSize = 50;
    
    // Edit the sort key as appropriate.
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor.alloc initWithKey:@"filename"
                                                                 ascending:YES];
    
    NSArray *sortDescriptors = @[sortDescriptor];
    
    fetchRequest.sortDescriptors = sortDescriptors;
    
    // Edit the section name key path and cache name if appropriate.
    // nil for section name key path means "no sections".
    NSFetchedResultsController *aFetchedResultsController = [NSFetchedResultsController.alloc initWithFetchRequest:fetchRequest
                                                                                              managedObjectContext:[NSManagedObjectContext MR_defaultContext].parentContext
                                                                                                sectionNameKeyPath:nil
                                                                                                         cacheName:@"Root"];
    aFetchedResultsController.delegate = self;
    self.fetchedResultsController = aFetchedResultsController;
    
	NSError *error = nil;
	if (![self.fetchedResultsController performFetch:&error]) {
        // Replace this implementation with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
	    NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
	    abort();
	}
    return _fetchedResultsController;
}


- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
    UICollectionView *collectionView = self.collectionView;
    
    
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [self.collectionView insertItemsAtIndexPaths:@[newIndexPath]];
            break;
            
        case NSFetchedResultsChangeDelete:
            [collectionView deleteItemsAtIndexPaths:@[indexPath]];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [self configureCell:(Cell *)[collectionView cellForItemAtIndexPath:indexPath] atIndexPath:indexPath];
            break;
            
        case NSFetchedResultsChangeMove:
            [collectionView deleteItemsAtIndexPaths:@[indexPath]];
            [collectionView insertItemsAtIndexPaths:@[newIndexPath]];
            break;
    }
}


#pragma mark - Pinch effect
- (void)handlePinchGesture:(UIPinchGestureRecognizer *)sender
{
    PinchLayout* pinchLayout = (PinchLayout*)self.collectionView.collectionViewLayout;
    
    if (sender.state == UIGestureRecognizerStateBegan)
    {
        CGPoint initialPinchPoint = [sender locationInView:self.collectionView];
        NSIndexPath* pinchedCellPath = [self.collectionView indexPathForItemAtPoint:initialPinchPoint];
        pinchLayout.pinchedCellPath = pinchedCellPath;
        
    }
    
    else if (sender.state == UIGestureRecognizerStateChanged)
    {
        pinchLayout.pinchedCellScale = sender.scale;
        pinchLayout.pinchedCellCenter = [sender locationInView:self.collectionView];
    }
    
    else
    {
        [self.collectionView performBatchUpdates:^{
            pinchLayout.pinchedCellPath = nil;
            pinchLayout.pinchedCellScale = 1.0;
        } completion:nil];
    }
}

@end
