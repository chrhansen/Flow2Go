//
//  AnalysisViewController.m
//  Flow2Go
//
//  Created by Christian Hansen on 21/08/12.
//  Copyright (c) 2012 Christian Hansen. All rights reserved.
//

#import "FGAnalysisViewController.h"
#import "FGPlotViewController.h"
#import "FGFolder.h"
#import "FGAnalysis.h"
#import "FGFCSFile.h"
#import "FGMeasurement+Management.h"
#import "FGPlot+Management.h"
#import "FGGate+Management.h"
#import "FGPlotDetailTableViewController.h"
#import "FGPlotCell.h"
#import "KGNoise.h"
#import "UIBarButtonItem+Customview.h"
#import "NSString+UUID.h"
#import "NSString+_Format.h"
#import "NSManagedObjectContext+Clone.h"
#import "FGAnalysisManager.h"
#import "FGGraph.h"

@interface FGAnalysisViewController () <PlotViewControllerDelegate, PlotDetailTableViewControllerDelegate, UIPopoverControllerDelegate, NSFetchedResultsControllerDelegate, FGFCSProgressDelegate>

@property (nonatomic, strong) FGFCSFile *fcsFile;
@property (nonatomic, strong) UIPopoverController *detailPopoverController;
@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, strong) NSMutableArray *objectChanges;
@property (nonatomic, strong) NSMutableArray *sectionChanges;
@property (nonatomic, strong) MBProgressHUD *progressHUD;
@property (nonatomic, strong) FGGraph *graph;
@property (nonatomic, strong) FGPlotViewController *plotViewController;

@end

@implementation FGAnalysisViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    _objectChanges = [NSMutableArray array];
    _sectionChanges = [NSMutableArray array];
    [self _addNoiseBackground];
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    // avoid loading graph when user is panning
    
    [self performSelector:@selector(prepareGraph) onThread:[NSThread mainThread] withObject:nil waitUntilDone:NO modes:@[NSDefaultRunLoopMode]];
    [self performSelector:@selector(preparePlotViewController) onThread:[NSThread mainThread] withObject:nil waitUntilDone:NO modes:@[NSDefaultRunLoopMode]];
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



- (void)showAnalysis:(FGAnalysis *)analysis
{
    if (!analysis || (_analysis == analysis)) return;
    
    self.analysis = analysis;
    self.title = self.analysis.name;
    if (self.analysis.plots.count == 0 || self.analysis.plots == nil) {
        [FGPlot createRootPlotForAnalysis:self.analysis];
    }
    [self _updateFetchedAnalysis:analysis];
    [self updateCollectionViewAfterFetch];
    [self _reloadFCSFile];
}

- (void)_reloadFCSFile
{
    [self.view addSubview:self.progressHUD];
//    [self.progressHUD show:NO];
    self.fcsFile = nil;
    self.fcsFile = [[FGFCSFile alloc] init];
    NSError *error;
    self.fcsFile = [FGFCSFile fcsFileWithPath:self.analysis.measurement.fullFilePath lastParsingSegment:FGParsingSegmentAnalysis error:&error];
    
    
    
//    [self.fcsFile readFCSFileAtPath:self.analysis.measurement.fullFilePath progressDelegate:self withCompletion:^(NSError *error) {
//        if (error) {
//            NSString *errorMessage = [@"Error reading fcs-file:" stringByAppendingFormat:@" %@", error.userInfo[@"error"]];
//            [FGErrorReporter showErrorMess:errorMessage inView:self.view];
//        }
//        [self.progressHUD hide:YES];
//    }];
}

- (void)addNavigationPaneBarbuttonWithTarget:(id)barButtonResponder selector:(SEL)barButtonSelector;
{
    UIBarButtonItem *barButton = [UIBarButtonItem barButtonWithImage:[UIImage imageNamed:@"FGBarButtonIconNavigationPane"] style:UIBarButtonItemStylePlain target:barButtonResponder action:barButtonSelector];
    self.navigationItem.leftBarButtonItem = barButton;
}

- (IBAction)applyToAllTapped:(id)sender
{
    NSOrderedSet *measurementsInFolder = self.analysis.measurement.folder.measurements;
    for (FGMeasurement *measurement in measurementsInFolder) {
        if ([measurement isEqual:self.analysis.measurement]) {
            NSLog(@"Skipping self's measurement");
            continue;
        }
        FGAnalysis *oldAnalysis = measurement.analyses.firstObject;
        oldAnalysis.measurement = NULL;
        [oldAnalysis deleteEntity];
        FGAnalysis *analysisCopy = (FGAnalysis *)[self.analysis.managedObjectContext clone:self.analysis];
        analysisCopy.measurement = measurement;
        [[FGAnalysisManager sharedInstance] performAnalysis:analysisCopy withCompletion:^(NSError *error) {
            NSLog(@"Completed analysis for measurement: %@", measurement.filename);
        }];
    }
}


- (void)prepareGraph
{
    if (!self.graph) {
        self.graph = [[FGGraph alloc] initWithFrame:[self boundsThatFitsWithinStatusBarInAllOrientations] themeNamed:kCPTSlateTheme];
    }
}


- (void)preparePlotViewController
{
    if (!self.plotViewController) {
        self.plotViewController = (FGPlotViewController *)[self.storyboard instantiateViewControllerWithIdentifier:@"plotViewController"];
        self.plotViewController.delegate = self;
        self.plotViewController.graph = self.graph;
        self.plotViewController.graph.dataSource = self.plotViewController;
        self.plotViewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
        self.plotViewController.modalPresentationStyle = UIModalPresentationFormSheet;
    }
}


#pragma mark - FGFCSFile Progress Delegate
- (void)loadProgress:(CGFloat)progress forFCSFile:(FGFCSFile *)fcsFile
{
    NSLog(@"progress: %f", progress); //TODO: delegate call back currently not implemented
}

- (MBProgressHUD *)progressHUD
{
    if (_progressHUD == nil) {
        _progressHUD = [MBProgressHUD.alloc initWithView:self.view];
        _progressHUD.labelText = NSLocalizedString(@"Reading FCS file", nil);
        _progressHUD.detailsLabelFont = _progressHUD.labelFont;
        [_progressHUD setMultipleTouchEnabled:YES];
        [_progressHUD setUserInteractionEnabled:YES];;
    }
    return _progressHUD;
}


- (UICollectionViewCell *)cellForPlot:(FGPlot *)plot
{
    NSUInteger row = [self.analysis.plots indexOfObject:plot] ;
    return [self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:row inSection:0]];
}


- (void)configureCell:(UICollectionViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    FGPlot *plot = [self.fetchedResultsController objectAtIndexPath:indexPath];
    FGPlotCell *plotCell = (FGPlotCell *)cell;
    FGGate *parentGate = (FGGate *)plot.parentNode;
    NSUInteger allEvents = self.analysis.measurement.countOfEvents.integerValue;
    if (parentGate) {
        plotCell.nameLabel.text = plot.name;
        plotCell.countLabel.text = [NSString countsAndPercentageAsString:parentGate.countOfEvents.integerValue ofAll:allEvents];
    } else {
        plotCell.nameLabel.text = [self.analysis.measurement.filename.stringByDeletingPathExtension fitToLength:32];
        plotCell.countLabel.text = [NSString countsAndPercentageAsString:allEvents ofAll:allEvents];
    }
    plotCell.plotImageView.image = plot.image;
    [plotCell.infoButton addTarget:self action:@selector(infoButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    plotCell.populationLabel.text = [plot.parentGateNames componentsJoinedByString:@"/"];
}


#pragma mark - UICollectionView Datasource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    id <NSFetchedResultsSectionInfo> sectionInfo = self.fetchedResultsController.sections[section];
    return sectionInfo.numberOfObjects;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Plot Cell";
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:CellIdentifier forIndexPath:indexPath];
    if (cell) [self configureCell:cell atIndexPath:indexPath];
    return cell;
}


#pragma mark - UICollectionView Delegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    FGPlot *plot = [self.analysis.plots objectAtIndex:indexPath.row];
    [self _presentPlot:plot];
}


- (void)infoButtonTapped:(UIButton *)infoButton
{
    UICollectionViewCell *cell = (UICollectionViewCell *)infoButton.superview.superview;
    NSIndexPath *indexPath = [self.collectionView indexPathForCell:cell];
    
    UINavigationController *plotNavigationVC = [self.storyboard instantiateViewControllerWithIdentifier:@"plotDetailTableViewController"];
    FGPlotDetailTableViewController *plotTVC = (FGPlotDetailTableViewController *)plotNavigationVC.topViewController;
    plotTVC.delegate = self;
    plotTVC.plot = [self.analysis.plots objectAtIndex:indexPath.row];
    if (self.detailPopoverController.isPopoverVisible) {
        UINavigationController *navCon = (UINavigationController *)self.detailPopoverController.contentViewController;
        [self.detailPopoverController dismissPopoverAnimated:YES];
        if ([navCon.topViewController isKindOfClass:FGPlotDetailTableViewController.class]) {
            return;
        }
    }
    if (IS_IPAD) {
        self.detailPopoverController = [UIPopoverController.alloc initWithContentViewController:plotNavigationVC];
        self.detailPopoverController.delegate = self;
        [self.detailPopoverController presentPopoverFromRect:infoButton.frame inView:cell.contentView permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    } else {
        [self presentViewController:plotNavigationVC animated:YES completion:nil];
    }
    [plotTVC setEditing:NO animated:YES];
}


- (void)_presentPlot:(FGPlot *)plot
{
    if (!self.fcsFile) {
        [FGErrorReporter showErrorMess:NSLocalizedString(@"Error: FCS-file not loaded.", nil) inView:self.view];
        return;
    }
    self.plotViewController.plot = plot;
    [self presentViewController:self.plotViewController animated:YES completion:nil];
    self.plotViewController.view.superview.bounds = [self boundsThatFitsWithinStatusBarInAllOrientations];
}


- (CGRect)boundsThatFitsWithinStatusBarInAllOrientations
{
    CGSize applicationFrameSize = [[UIScreen mainScreen] applicationFrame].size;
    CGFloat minSideLengthMinusStatusBar = MIN(applicationFrameSize.width, applicationFrameSize.height);
    if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation)) {
        CGSize statusBarSize = [UIApplication sharedApplication].statusBarFrame.size;
        minSideLengthMinusStatusBar -= MIN(statusBarSize.width, statusBarSize.height);
    }
    return CGRectMake(0, 0, minSideLengthMinusStatusBar, minSideLengthMinusStatusBar);
}


- (void)deletePlot:(FGPlot *)plotToBeDeleted
{
    __block BOOL deleteSuccess = NO;
    NSManagedObjectID *objectID = plotToBeDeleted.objectID;
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        FGPlot *localPlot = (FGPlot *)[localContext objectWithID:objectID];
        deleteSuccess = [localPlot deleteInContext:localContext];
    } completion:^(BOOL success, NSError *error) {
        if (!deleteSuccess) {
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


#pragma mark - PlotViewController delegate
- (FGFCSFile *)fcsFileForPlot:(FGPlot *)plot
{
    return self.fcsFile;
}

- (void)plotViewController:(FGPlotViewController *)plotViewController didRequestNewPlotWithPopulationInGate:(FGGate *)gate
{
    [plotViewController setDisplayedSubset:nil]; // TODO: set to inherit from previous plot and apply new gate
    [self dismissViewControllerAnimated:YES completion:^{
        plotViewController.plot = nil;
        FGPlot *newPlot = [FGPlot createPlotForAnalysis:self.analysis parentNode:gate];
        [self.collectionView reloadData];
        if (newPlot) {
            [self _presentPlot:newPlot];
        } else {
            NSLog(@"Error creating new plot for gate: %@", gate);
        }
        NSError *error;
        [newPlot.managedObjectContext save:&error];
        if (error) NSLog(@"Error saving new plot: %@", newPlot);
    }];
}

- (void)plotViewController:(FGPlotViewController *)plotViewController didTapDoneForPlot:(FGPlot *)plot
{
    [plotViewController setDisplayedSubset:nil];
    [self dismissViewControllerAnimated:YES completion:^{
        self.plotViewController.plot = nil;
        NSIndexPath *indexPath = [self.fetchedResultsController indexPathForObject:plot];
        [self configureCell:[self.collectionView cellForItemAtIndexPath:indexPath] atIndexPath:indexPath];
        [plot.managedObjectContext saveToPersistentStoreAndWait];
    }];
}

#pragma mark - Plot Table View Controller delegate

- (void)didTapDeletePlot:(FGPlotDetailTableViewController *)sender
{
    __weak FGPlot *plotToBeDeleted = sender.plot;
    if ([self.presentedViewController isKindOfClass:FGPlotViewController.class]) {
        [self dismissViewControllerAnimated:YES completion:^{
            [self deletePlot:plotToBeDeleted];
            [self.collectionView reloadData];
        }];
    } else {
        [self.detailPopoverController dismissPopoverAnimated:YES];
        [self deletePlot:plotToBeDeleted];
        [self.collectionView reloadData];
    }
}

#pragma mark - Fetched results controller
- (void)_updateFetchedAnalysis:(FGAnalysis *)newAnalysis
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF IN %@", newAnalysis.plots];
    [self.fetchedResultsController.fetchRequest setPredicate:predicate];
    NSError *error = nil;
    if (![[self fetchedResultsController] performFetch:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
}


- (NSFetchedResultsController *)fetchedResultsController
{
    if (_fetchedResultsController != nil) {
        return _fetchedResultsController;
    }
    if (self.analysis == nil) {
        return nil;
    }
    _fetchedResultsController = [FGPlot fetchAllGroupedBy:nil
                                            withPredicate:[NSPredicate predicateWithFormat:@"SELF IN %@", self.analysis.plots]
                                                 sortedBy:@"dateCreated"
                                                ascending:YES
                                                 delegate:self
                                                inContext:[NSManagedObjectContext MR_defaultContext]];
    return _fetchedResultsController;
}


- (void)updateCollectionViewAfterFetch
{
    NSUInteger initialItemCount = [self.collectionView numberOfItemsInSection:0];
    NSUInteger currentItemCount = [self.fetchedResultsController.fetchedObjects count];
    NSMutableArray *indexPaths = [NSMutableArray array];
    if (initialItemCount > currentItemCount) {
        for (NSUInteger itemNo = currentItemCount; itemNo < initialItemCount; itemNo++) {
            [indexPaths addObject:[NSIndexPath indexPathForItem:itemNo inSection:0]];
        }
        [self.collectionView deleteItemsAtIndexPaths:indexPaths];
    } else if (initialItemCount < currentItemCount) {
        for (NSUInteger itemNo = initialItemCount; itemNo < currentItemCount; itemNo++) {
            [indexPaths addObject:[NSIndexPath indexPathForItem:itemNo inSection:0]];
        }
        [self.collectionView insertItemsAtIndexPaths:indexPaths];
    }
    for (NSUInteger itemNo = 0; itemNo < currentItemCount; itemNo++) {
        [self.collectionView reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:itemNo inSection:0]]];
    }
}







































































#pragma mark - Fetched Results Controller Delegate methods
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
                                [self configureCell:[self.collectionView cellForItemAtIndexPath:obj] atIndexPath:obj];
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
