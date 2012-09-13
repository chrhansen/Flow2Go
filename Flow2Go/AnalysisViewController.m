//
//  AnalysisViewController.m
//  Flow2Go
//
//  Created by Christian Hansen on 21/08/12.
//  Copyright (c) 2012 Christian Hansen. All rights reserved.
//

#import "AnalysisViewController.h"
#import "PlotViewController.h"
#import "Analysis.h"
#import "FCSFile.h"
#import "Measurement.h"
#import "Plot.h"
#import "Gate.h"
#import "PinchLayout.h"
#import "PlotDetailTableViewController.h"


@interface AnalysisViewController () <PlotViewControllerDelegate, PlotDetailTableViewControllerDelegate, UIPopoverControllerDelegate>
{
    NSMutableArray *_sectionChanges;
    NSMutableArray *_objectChanges;
}
@property (nonatomic, strong) FCSFile *fcsFile;
@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, strong) UIPopoverController *detailPopoverController;
@property (nonatomic, strong) NSMutableArray *objectChanges;

@end

@implementation AnalysisViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    UIPinchGestureRecognizer* pinchRecognizer = [UIPinchGestureRecognizer.alloc initWithTarget:self
                                                                                        action:@selector(handlePinchGesture:)];
    [self.collectionView addGestureRecognizer:pinchRecognizer];
    
    self.navigationItem.rightBarButtonItem = [UIBarButtonItem.alloc initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                         target:self
                                                                                         action:@selector(doneTapped)];
    UINib *cellNib = [UINib nibWithNibName:@"PlotCellView" bundle:NSBundle.mainBundle];
    [self.collectionView registerNib:cellNib forCellWithReuseIdentifier:@"Plot Cell"];

    self.title = self.analysis.name;

    if (self.analysis.plots.count == 0)
    {
        [Plot createPlotForAnalysis:self.analysis parentNode:nil];
    }
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self _configureButtons];
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self _loadFCSFile];
}


- (void)viewDidUnload
{
    [NSNotificationCenter.defaultCenter removeObserver:self];
    [super viewDidUnload];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)_loadFCSFile
{
    if (!_fcsFile)
    {
        NSError *error;
        self.fcsFile = [FCSFile fcsFileWithPath:[HOME_DIR stringByAppendingPathComponent:self.analysis.measurement.filepath] error:&error];
        if (self.fcsFile == nil)
        {
            NSLog(@"Error: %@", error.localizedDescription);
        }
    }
}


- (void)_configureButtons
{
    UIButton *infoButton = [UIButton buttonWithType:UIButtonTypeInfoLight];
    [infoButton addTarget:self action:@selector(_toggleAnalysisInfo:) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.leftBarButtonItem  = [UIBarButtonItem.alloc initWithCustomView: infoButton];
}

- (void)configureCell:(UICollectionViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    
    Plot *plot = [self.fetchedResultsController objectAtIndexPath:indexPath];
    Gate *parentGate = (Gate *)plot.parentNode;
    
    NSLog(@"Name: %@, Section: %@", plot.name, plot.plotSectionName);
    
    UILabel *nameLabel = (UILabel *)[cell viewWithTag:1];
    nameLabel.text = plot.name;

    UILabel *countLabel = (UILabel *)[cell viewWithTag:2];
    countLabel.text = [NSString stringWithFormat:@"%i cells", parentGate.cellCount.integerValue];

    UILabel *xParName = (UILabel *)[cell viewWithTag:3];
    xParName.text = plot.xParName;

    UILabel *yParName = (UILabel *)[cell viewWithTag:4];
    yParName.text = plot.yParName;
    
    UIButton *infoButton = (UIButton *)[cell viewWithTag:5];
    [infoButton addTarget:self action:@selector(infoButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    
    if (parentGate == nil)
    {
        nameLabel.text = [NSString stringWithFormat:@"%@", self.analysis.measurement.filename];
        countLabel.text = [NSString stringWithFormat:@"%i cells", self.analysis.measurement.countOfEvents.integerValue];
    }
}


- (void)infoButtonTapped:(UIButton *)infoButton
{
    UICollectionViewCell *cell = (UICollectionViewCell *)infoButton.superview.superview;
    NSIndexPath *indexPath = [self.collectionView indexPathForCell:cell];
    
    UINavigationController *plotNavigationVC = [self.storyboard instantiateViewControllerWithIdentifier:@"plotDetailTableViewController"];
    PlotDetailTableViewController *plotTVC = (PlotDetailTableViewController *)plotNavigationVC.topViewController;
    plotTVC.delegate = self;
    plotTVC.plot = [self.fetchedResultsController objectAtIndexPath:indexPath];
    if (self.detailPopoverController.isPopoverVisible)
    {
        UINavigationController *navCon = (UINavigationController *)self.detailPopoverController.contentViewController;
        [self.detailPopoverController dismissPopoverAnimated:YES];
        if ([navCon.topViewController isKindOfClass:PlotDetailTableViewController.class])
        {
            return;
        }
    }
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad)
    {
        self.detailPopoverController = [UIPopoverController.alloc initWithContentViewController:plotNavigationVC];
        self.detailPopoverController.delegate = self;
        [self.detailPopoverController presentPopoverFromRect:infoButton.frame inView:cell.contentView permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    }
    else if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone)
    {
        [self presentViewController:plotNavigationVC animated:YES completion:nil];
    }
    [plotTVC setEditing:NO animated:YES];
}


- (void)_toggleAnalysisInfo:(id)sender
{
    NSLog(@"Toggle Analysis info");
}

- (void)doneTapped
{
    for (UIView *aSubView in self.view.subviews)
    {
        [aSubView removeFromSuperview];
    }
    [self dismissViewControllerAnimated:YES completion:^{
        [self.fcsFile cleanUpEventsForFCSFile];
    }];
}


- (FCSFile *)fcsFile
{
    if (!_fcsFile)
    {
        NSError *error;
        _fcsFile = [FCSFile fcsFileWithPath:[DOCUMENTS_DIR stringByAppendingPathComponent:self.analysis.measurement.filename] error:&error];
    }
    return _fcsFile;
}

- (void)_presentPlot:(Plot *)plot
{
    UINavigationController *navigationController = [self.storyboard instantiateViewControllerWithIdentifier:@"plotViewController"];
    PlotViewController *plotViewController = (PlotViewController *)navigationController.topViewController;
    plotViewController.delegate = self;
    plotViewController.plot = plot;
    [self presentViewController:navigationController animated:YES completion:nil];    
}

#pragma mark - Popover Controller Delegate
- (BOOL)popoverControllerShouldDismissPopover:(UIPopoverController *)popoverController
{
    UINavigationController *navigationController = (UINavigationController *)popoverController.contentViewController;
    return !navigationController.topViewController.editing;
}

#pragma mark - Fetched results controller

- (NSFetchedResultsController *)fetchedResultsController
{
    if (_fetchedResultsController != nil) {
        return _fetchedResultsController;
    }
    
    NSFetchRequest *fetchRequest = [NSFetchRequest.alloc init];
    fetchRequest.entity = [NSEntityDescription entityForName:@"Plot"
                                      inManagedObjectContext:[NSManagedObjectContext MR_defaultContext]];
    fetchRequest.fetchBatchSize = 50;
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"analysis == %@", self.analysis];
    
    // Edit the sort key as appropriate.
    fetchRequest.sortDescriptors = @[[NSSortDescriptor.alloc initWithKey:@"dateCreated" ascending:YES]];
    
    NSFetchedResultsController *aFetchedResultsController = [NSFetchedResultsController.alloc initWithFetchRequest:fetchRequest
                                                                                              managedObjectContext:[NSManagedObjectContext MR_defaultContext].parentContext
                                                                                                sectionNameKeyPath:nil
                                                                                                         cacheName:nil];
    
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


#pragma mark - Fetched Resultscontroller delegate
- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    self.objectChanges = NSMutableArray.array;
    if (!_sectionChanges) {
        _sectionChanges = NSMutableArray.array;
    }
    if (!_objectChanges) {
        _objectChanges = NSMutableArray.array;
    }
}


- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id<NSFetchedResultsSectionInfo>)sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
    NSMutableDictionary *change = [NSMutableDictionary new];
    
    switch(type)
    {
        case NSFetchedResultsChangeInsert:
            change[@(type)] = [NSNumber numberWithUnsignedInteger:sectionIndex];
            break;
        case NSFetchedResultsChangeDelete:
            change[@(type)] = [NSNumber numberWithUnsignedInteger:sectionIndex];
            break;
    }
    
    [_sectionChanges addObject:change];
}



- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath
{
    NSMutableDictionary *change = [NSMutableDictionary new];
    switch(type)
    {
        case NSFetchedResultsChangeInsert:
            change[@(type)] = newIndexPath;
            break;
        case NSFetchedResultsChangeDelete:
            change[@(type)] = indexPath;
            break;
        case NSFetchedResultsChangeUpdate:
            change[@(type)] = indexPath;
            break;
        case NSFetchedResultsChangeMove:
            change[@(type)] = @[indexPath, newIndexPath];
            break;
    }
    [_objectChanges addObject:change];
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{    
    if ([_sectionChanges count] > 0)
    {
        [self.collectionView performBatchUpdates:^{
            
            for (NSDictionary *change in _sectionChanges)
            {
                [change enumerateKeysAndObjectsUsingBlock:^(NSNumber *key, id obj, BOOL *stop) {
                    
                    NSFetchedResultsChangeType type = [key unsignedIntegerValue];
                    switch (type)
                    {
                        case NSFetchedResultsChangeInsert:
                            [self.collectionView insertSections:[NSIndexSet indexSetWithIndex:[obj unsignedIntegerValue]]];
                            break;
                        case NSFetchedResultsChangeDelete:
                            [self.collectionView deleteSections:[NSIndexSet indexSetWithIndex:[obj unsignedIntegerValue]]];
                            break;
                        case NSFetchedResultsChangeUpdate:
                            [self.collectionView reloadSections:[NSIndexSet indexSetWithIndex:[obj unsignedIntegerValue]]];
                            break;
                    }
                }];
            }
        } completion:^(BOOL finished) {
            [self.fetchedResultsController performFetch:nil];
        }];
    }
    
    if ([_objectChanges count] > 0 && [_sectionChanges count] == 0)
    {
        [self.collectionView performBatchUpdates:^{
            
            for (NSDictionary *change in _objectChanges)
            {
                [change enumerateKeysAndObjectsUsingBlock:^(NSNumber *key, id obj, BOOL *stop) {
                    
                    NSFetchedResultsChangeType type = [key unsignedIntegerValue];
                    switch (type)
                    {
                        case NSFetchedResultsChangeInsert:
                            [self.collectionView insertItemsAtIndexPaths:@[obj]];
                            break;
                        case NSFetchedResultsChangeDelete:
                            [self.collectionView deleteItemsAtIndexPaths:@[obj]];
                            break;
                        case NSFetchedResultsChangeUpdate:
                            [self.collectionView reloadItemsAtIndexPaths:@[obj]];
                            break;
                        case NSFetchedResultsChangeMove:
                            [self.collectionView moveItemAtIndexPath:obj[0] toIndexPath:obj[1]];
                            break;
                    }
                }];
            }
        } completion:^(BOOL finished) {
            [self.fetchedResultsController performFetch:nil];
            //[self.collectionView reloadData];
            
        }];
    }
    
    [_sectionChanges removeAllObjects];
    [_objectChanges removeAllObjects];
}


#pragma mark - PlotViewController delegate
- (FCSFile *)fcsFile:(id)sender
{
    return self.fcsFile;
}


- (void)didSelectGate:(Gate *)gate forPlot:(Plot *)plot
{
    [self dismissViewControllerAnimated:YES completion:^{
        Plot *newPlot = [Plot createPlotForAnalysis:self.analysis parentNode:gate];
        newPlot.xAxisType = plot.xAxisType;
        newPlot.yAxisType = plot.yAxisType;
        [newPlot.managedObjectContext save];
        [self _presentPlot:newPlot];
    }];
}


- (void)didDeleteGate:(Gate *)gate
{
    [self.analysis.managedObjectContext save];
}


- (void)deletePlot:(Plot *)plotToBeDeleted
{
    BOOL success = [plotToBeDeleted deleteInContext:self.analysis.managedObjectContext];
    [self.analysis.managedObjectContext save];
    if (!success)
    {
        UIAlertView *alertView = [UIAlertView.alloc initWithTitle:NSLocalizedString(@"Error", nil)
                                                          message:[NSLocalizedString(@"Could not delete plot \"", nil) stringByAppendingFormat:@"%@\"", plotToBeDeleted.name]
                                                         delegate:nil
                                                cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                                otherButtonTitles: nil];
        [alertView show];
    }

}

#pragma mark - Plot Table View Controller delegate

- (void)didTapDeletePlot:(PlotDetailTableViewController *)sender
{
    __weak Plot *plotToBeDeleted = sender.plot;
    
    if ([self.presentedViewController isKindOfClass:PlotViewController.class])
    {
        [self dismissViewControllerAnimated:YES completion:^{
            [self deletePlot:plotToBeDeleted];
        }];
    }
    else
    {
        [self.detailPopoverController dismissPopoverAnimated:YES];
        [self deletePlot:plotToBeDeleted];
    }
}

#pragma mark - Collection View Data source
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return self.fetchedResultsController.sections.count;
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    id <NSFetchedResultsSectionInfo> sectionInfo = self.fetchedResultsController.sections[section];
    return sectionInfo.numberOfObjects;
}


- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Plot Cell" forIndexPath:indexPath];
    [self configureCell:cell atIndexPath:indexPath];
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    Plot *plot = [self.analysis.plots objectAtIndex:indexPath.row];
    [self _presentPlot:plot];
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
