//
//  AnalysisViewController.m
//  Flow2Go
//
//  Created by Christian Hansen on 21/08/12.
//  Copyright (c) 2012 Christian Hansen. All rights reserved.
//

#import "FGAnalysisViewController.h"
#import "FGPlotViewController.h"
#import "FGAnalysis.h"
#import "FCSFile.h"
#import "FGMeasurement.h"
#import "FGPlot+Management.h"
#import "FGGate+Management.h"
#import "PlotDetailTableViewController.h"
#import "FGPlotCell.h"
#import "KGNoise.h"
#import "UIBarButtonItem+Customview.h"

@interface FGAnalysisViewController () <PlotViewControllerDelegate, PlotDetailTableViewControllerDelegate, UIPopoverControllerDelegate, NSFetchedResultsControllerDelegate>

@property (nonatomic, strong) FCSFile *fcsFile;
@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, strong) NSMutableArray *objectChanges;
@property (nonatomic, strong) NSMutableArray *sectionChanges;
@property (nonatomic, strong) UIPopoverController *detailPopoverController;
@property (nonatomic) CGPoint pickedCellLocation;
@property (strong, nonatomic) UIPopoverController *masterPopoverController;

@end

@implementation FGAnalysisViewController
- (void)awakeFromNib
{
    [super awakeFromNib];
    _objectChanges = [NSMutableArray array];
    _sectionChanges = [NSMutableArray array];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self _addNoiseBackground];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)_addNoiseBackground
{
    KGNoiseRadialGradientView *collectionNoiseView = [[KGNoiseRadialGradientView alloc] initWithFrame:self.collectionView.bounds];
    collectionNoiseView.backgroundColor            = [UIColor colorWithWhite:0.7032 alpha:1.000];
    collectionNoiseView.alternateBackgroundColor   = [UIColor colorWithWhite:0.7051 alpha:1.000];
    collectionNoiseView.noiseOpacity = 0.07;
    collectionNoiseView.noiseBlendMode = kCGBlendModeNormal;
    self.collectionView.backgroundView = collectionNoiseView;
}


//- (void)showAnalysis:(FGAnalysis *)analysis
//{
//    if (!analysis) return;
//    
//    self.analysis = analysis;
//    self.title = self.analysis.name;
//    if (self.analysis.plots.count == 0 || self.analysis.plots == nil) {
//        [FGPlot createPlotForAnalysis:self.analysis parentNode:nil];
//    }
//    
//    _fetchedResultsController = [FGPlot fetchAllGroupedBy:nil
//                                            withPredicate:[NSPredicate predicateWithFormat:@"analysis == %@", analysis]
//                                                 sortedBy:@"dateCreated"
//                                                ascending:YES
//                                                 delegate:self
//                                                inContext:[NSManagedObjectContext MR_defaultContext]];
//    
//    [self.collectionView reloadData];
//    [self _reloadFCSFile];
//}

- (void)showAnalysis:(FGAnalysis *)analysis
{
    if (!analysis) return;
    if (_analysis == analysis) return;

    self.analysis = analysis;
    self.title = self.analysis.name;
    if (self.analysis.plots.count == 0 || self.analysis.plots == nil) {
        NSManagedObjectID *analysisID = analysis.objectID;
        [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
            FGAnalysis *localAnalysis = (FGAnalysis *)[localContext objectWithID:analysisID];
            [FGPlot createRootPlotForAnalysis:localAnalysis];
        }];
    }
    [self _reloadFCSFile];
    NSError *error;
    self.fetchedResultsController.fetchRequest.predicate = [NSPredicate predicateWithFormat:@"analysis == %@", self.analysis];
    [self.fetchedResultsController performFetch:&error];
    
    if (error) NSLog(@"Error performingFetch when showing analysis");
    [self.collectionView reloadData];
}

- (void)_reloadFCSFile
{
    [self.fcsFile cleanUpEventsForFCSFile];
    NSError *error;
    self.fcsFile = [FCSFile fcsFileWithPath:[HOME_DIR stringByAppendingPathComponent:self.analysis.measurement.filePath] error:&error];
    if (self.fcsFile == nil) NSLog(@"Error reloading FCS file: %@", error.localizedDescription);
}


- (void)configureCell:(UICollectionViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    FGPlot *plot = [self.fetchedResultsController objectAtIndexPath:indexPath];    
    FGGate *parentGate = (FGGate *)plot.parentNode;
    FGPlotCell *plotCell = (FGPlotCell *)cell;
    
    plotCell.nameLabel.text = plot.name;
    plotCell.countLabel.text = [NSString stringWithFormat:@"%i cells", parentGate.cellCount.integerValue];
    plotCell.plotImageView.image = plot.image;

    
    
    [plotCell.infoButton addTarget:self action:@selector(infoButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    
    if (parentGate == nil) {
        plotCell.nameLabel.text = [NSString stringWithFormat:@"%@", self.analysis.measurement.filename];
        plotCell.countLabel.text = [NSString stringWithFormat:@"%i cells", self.analysis.measurement.countOfEvents.integerValue];
    }
}

#pragma mark - UICollectionView Datasource
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return self.fetchedResultsController.sections.count;
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    id <NSFetchedResultsSectionInfo> sectionInfo = self.fetchedResultsController.sections[section];
    NSLog(@"sectionInfo.numberOfObjects: %d", sectionInfo.numberOfObjects);
    return sectionInfo.numberOfObjects;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Plot Cell";
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:CellIdentifier forIndexPath:indexPath];
    if (cell) [self configureCell:cell atIndexPath:indexPath];
    return cell;
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


- (FCSFile *)fcsFile
{
    if (!_fcsFile)
    {
        NSError *error;
        _fcsFile = [FCSFile fcsFileWithPath:[DOCUMENTS_DIR stringByAppendingPathComponent:self.analysis.measurement.filename] error:&error];
    }
    return _fcsFile;
}


#define PLOTVIEWSIZE 700
#define NAVIGATION_BAR_HEIGHT 44

- (void)_presentPlot:(FGPlot *)plot
{
    NSIndexPath *indexPath = [self.fetchedResultsController indexPathForObject:plot];
    UICollectionViewCell *cell = [self.collectionView cellForItemAtIndexPath:indexPath];
    self.pickedCellLocation = cell.center;
    UIImageView *plotImageView = (UIImageView *)[cell viewWithTag:6];
    CGRect destBounds = CGRectMake(0, 0, PLOTVIEWSIZE, PLOTVIEWSIZE);
    CGPoint destCenter = CGPointMake(self.collectionView.window.bounds.size.width / 2.0, self.collectionView.window.bounds.size.height / 2.0);
    
    [UIView animateWithDuration:0.2 animations:^{
        [self _hideLabels:YES forCell:cell];
        [self.collectionView bringSubviewToFront:cell];
        plotImageView.bounds = destBounds;
        plotImageView.center = [self.collectionView.window convertPoint:destCenter toView:self.collectionView];
        cell.bounds = destBounds;
        cell.center = [self.collectionView.window convertPoint:destCenter toView:self.collectionView];
    } completion:^(BOOL finished) {
        UINavigationController *navigationController = [self.storyboard instantiateViewControllerWithIdentifier:@"plotViewController"];
        FGPlotViewController *plotViewController = (FGPlotViewController *)navigationController.topViewController;
        plotViewController.delegate = self;
        plotViewController.plot = plot;
        navigationController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        navigationController.modalPresentationStyle = UIModalPresentationPageSheet;
        navigationController.navigationBar.translucent = YES;
        [navigationController setNavigationBarHidden:YES animated:NO];
        [self presentViewController:navigationController animated:NO completion:nil];
        navigationController.view.superview.frame  = destBounds; 
        navigationController.view.superview.center = destCenter;
    }];
}


- (void)_hideLabels:(BOOL)hidden forCell:(UICollectionViewCell *)cell
{
    UILabel *nameLabel = (UILabel *)[cell viewWithTag:1];
    nameLabel.hidden = hidden;
    
    UILabel *countLabel = (UILabel *)[cell viewWithTag:2];
    countLabel.hidden = hidden;
    
    UIButton *infoButton = (UIButton *)[cell viewWithTag:5];
    infoButton.hidden = hidden;
}


- (void)deletePlot:(FGPlot *)plotToBeDeleted
{
    __block BOOL success = NO;
    NSManagedObjectID *objectID = plotToBeDeleted.objectID;
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        FGPlot *localPlot = (FGPlot *)[localContext objectWithID:objectID];
        success = [localPlot deleteInContext:localContext];
    } completion:^(BOOL success, NSError *error) {
        if (!success) {
            UIAlertView *alertView = [UIAlertView.alloc initWithTitle:NSLocalizedString(@"Error", nil)
                                                              message:[NSLocalizedString(@"Could not delete plot \"", nil) stringByAppendingFormat:@"%@\"", plotToBeDeleted.name]
                                                             delegate:nil
                                                    cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                                    otherButtonTitles: nil];
            [alertView show];
        }
    }];
}


#pragma mark - Popover Controller Delegate
- (BOOL)popoverControllerShouldDismissPopover:(UIPopoverController *)popoverController
{
    UINavigationController *navigationController = (UINavigationController *)popoverController.contentViewController;
    return !navigationController.topViewController.editing;
}

#pragma mark - Fetched results controller
#pragma mark - Fetched Results Controller
- (NSFetchedResultsController *)fetchedResultsController
{
    if (_fetchedResultsController != nil) {
        return _fetchedResultsController;
    }
    _fetchedResultsController = [FGPlot fetchAllGroupedBy:nil
                                            withPredicate:[NSPredicate predicateWithFormat:@"self.analysis == %@", self.analysis]
                                                 sortedBy:@"dateCreated"
                                                ascending:YES
                                                 delegate:self
                                                inContext:[NSManagedObjectContext MR_defaultContext]];
    return _fetchedResultsController;
}


#pragma mark - PlotViewController delegate
- (FCSFile *)fcsFileForPlot:(FGPlot *)plot
{
    return self.fcsFile;
}


- (void)plotViewController:(FGPlotViewController *)plotViewController didSelectGate:(FGGate *)gate forPlot:(FGPlot *)plot
{
    [self dismissViewControllerAnimated:YES completion:^{
        FGPlot *newPlot = [FGPlot createPlotForAnalysis:self.analysis parentNode:gate];
        newPlot.xAxisType = plot.xAxisType;
        newPlot.yAxisType = plot.yAxisType;
        NSError *error;
        [newPlot.managedObjectContext save:&error];
        if (!error) {
            [self _presentPlot:newPlot];
        } else {
            NSLog(@"Error creating new plot for gate: %@", gate);
        }
    }];
}

- (void)plotViewController:(FGPlotViewController *)plotViewController didTapDoneForPlot:(FGPlot *)plot
{
    NSIndexPath *indexPath = [self.fetchedResultsController indexPathForObject:plot];
    UICollectionViewCell *cell = [self.collectionView cellForItemAtIndexPath:indexPath];
    cell.bounds = plotViewController.view.bounds;
    
    UIImageView *plotImageView = (UIImageView *)[cell viewWithTag:6];
    plotImageView.bounds = cell.bounds;

    [self dismissViewControllerAnimated:NO completion:nil];
    CGRect destBounds = CGRectMake(0, 0, 250, 250);

    [UIView animateWithDuration:0.5 animations:^{
        plotImageView.bounds = destBounds;
        plotImageView.center = self.pickedCellLocation;
        cell.bounds = destBounds;
        cell.center = self.pickedCellLocation;
    } completion:^(BOOL finished) {
        [self _hideLabels:NO forCell:cell];
        NSError *error;
        [plot.managedObjectContext save:&error];
        if (error) NSLog(@"Error saving plot: %@", error.localizedDescription);
    }];
}

#pragma mark - Plot Table View Controller delegate

- (void)didTapDeletePlot:(PlotDetailTableViewController *)sender
{
    __weak FGPlot *plotToBeDeleted = sender.plot;
    
    if ([self.presentedViewController isKindOfClass:FGPlotViewController.class]) {
        [self dismissViewControllerAnimated:YES completion:^{
            [self deletePlot:plotToBeDeleted];
        }];
    } else {
        [self.detailPopoverController dismissPopoverAnimated:YES];
        [self deletePlot:plotToBeDeleted];
    }
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    FGPlot *plot = [self.analysis.plots objectAtIndex:indexPath.row];
    [self _presentPlot:plot];
}
































#pragma mark Fetched Results Controller Delegate methods
- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
    NSMutableDictionary *change = [NSMutableDictionary new];
    switch(type)
    {
        case NSFetchedResultsChangeInsert:
            change[@(type)] = @(sectionIndex);
            break;
        case NSFetchedResultsChangeDelete:
            change[@(type)] = @(sectionIndex);
            break;
    }
    [_sectionChanges addObject:change];
}


- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
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
    [self _performOutstandingCollectionViewUpdates];
}


- (void)_performOutstandingCollectionViewUpdates
{
    if (self.navigationController.visibleViewController != self)
    {
        [self.collectionView reloadData];
    }
    else
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
            } completion:nil];
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
            } completion:nil];
        }
    }
    
    [_sectionChanges removeAllObjects];
    [_objectChanges removeAllObjects];
}


@end
