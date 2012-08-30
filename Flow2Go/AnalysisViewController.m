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
#import "PlotCell.h"
#import "Measurement.h"
#import "Plot.h"
#import "Gate.h"
#import "PinchLayout.h"

@interface AnalysisViewController () <PlotViewControllerDelegate>

@property (nonatomic, strong) FCSFile *fcsFile;
@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;

@end

@implementation AnalysisViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    UIPinchGestureRecognizer* pinchRecognizer = [UIPinchGestureRecognizer.alloc initWithTarget:self
                                                                                        action:@selector(handlePinchGesture:)];
    [self.collectionView addGestureRecognizer:pinchRecognizer];
    [self.collectionView registerClass:PlotCell.class forCellWithReuseIdentifier:@"Plot Cell"];
    
    self.navigationItem.rightBarButtonItem = [UIBarButtonItem.alloc initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                         target:self
                                                                                         action:@selector(doneTapped)];
    if (self.analysis.plots.count == 0)
    {
        [Plot createPlotForAnalysis:self.analysis parentNode:nil];
    }
    
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (!_fcsFile)
    {
        self.fcsFile = [FCSFile fcsFileWithPath:[HOME_DIR stringByAppendingPathComponent:self.analysis.measurement.filepath]];
    }
//    
//    NSLog(@"sections: %i", self.fetchedResultsController.sections.count);
//    for (id <NSFetchedResultsSectionInfo> sectionInfo in self.fetchedResultsController.sections)
//    {
//        NSLog(@"numberOfObjects: %i", [sectionInfo numberOfObjects]);
//        for (id object in sectionInfo.objects)
//        {
//            if ([object isKindOfClass:Plot.class]) {
//                NSLog(@"%@, #level: %i", (Plot *)object, [(Plot *)object countOfParentGates]);
//            }
//            else
//            {
//                NSLog(@"Not plot %@", [object class]);
//            }
//        }
//    }
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

- (void)configureCell:(UICollectionViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    Plot *plot = [self.analysis.plots objectAtIndex:indexPath.row];
    Gate *parentGate = (Gate *)plot.parentNode;
    PlotCell *plotCell = (PlotCell *)cell;
    plotCell.cellCount.text = [NSString stringWithFormat:@"%i cells", parentGate.cellCount.integerValue];
    plotCell.parentGateName.text = parentGate.name;
    
    if (parentGate == nil)
    {
        plotCell.cellCount.text = [NSString stringWithFormat:@"%i cells", self.analysis.measurement.countOfEvents.integerValue];
        plotCell.parentGateName.text = [NSString stringWithFormat:@"%@", self.analysis.measurement.filename];
    }
    
    plotCell.xAxisName.text = @"test X";
    plotCell.yAxisName.text = @"test Y";
}


- (void)_addObservings
{
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(_analysisUpdated:) name:AnalysisUpdatedNotification object:nil];
}

- (void)_analysisUpdated:(NSNotification *)notification
{
    if (notification.object == self.analysis)
    {
        [self.collectionView reloadData];
    }
}


- (void)doneTapped
{
    for (UIView *aSubView in self.view.subviews)
    {
        [aSubView removeFromSuperview];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}


- (FCSFile *)fcsFile
{
    if (!_fcsFile)
    {
        _fcsFile = [FCSFile fcsFileWithPath:[DOCUMENTS_DIR stringByAppendingPathComponent:self.analysis.measurement.filename]];
    }
    return _fcsFile;
}

- (void)_presentPlot:(Plot *)plot
{
    UINavigationController *navigationController = [self.storyboard instantiateViewControllerWithIdentifier:@"plotViewController"];
    PlotViewController *plotViewController = (PlotViewController *)navigationController.topViewController;
    plotViewController.delegate = self;
    plotViewController.plot = plot;
    [plotViewController prepareDataForPlot];
    [self presentViewController:navigationController animated:YES completion:nil];    
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
    
    // Set the batch size to a suitable number.
    fetchRequest.fetchBatchSize = 50;
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"analysis == %@", self.analysis];
    
    // Edit the sort key as appropriate.
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor.alloc initWithKey:@"parentNode"
                                                                 ascending:YES];
    
    NSArray *sortDescriptors = @[sortDescriptor];
    
    fetchRequest.sortDescriptors = sortDescriptors;
    

    
    // Edit the section name key path and cache name if appropriate.
    // nil for section name key path means "no sections".
    NSFetchedResultsController *aFetchedResultsController = [NSFetchedResultsController.alloc initWithFetchRequest:fetchRequest
                                                                                              managedObjectContext:[NSManagedObjectContext MR_defaultContext].parentContext
                                                                                                sectionNameKeyPath:@"parentNode.name"
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
        [self.collectionView reloadData];
        [self _presentPlot:newPlot];
    }];
}

#pragma mark - Collection View Data source
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.analysis.plots.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Plot Cell"
                                                                           forIndexPath:indexPath];
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
