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
#import "FGMeasurement+Management.h"
#import "FGPlot+Management.h"
#import "FGGate+Management.h"
#import "PlotDetailTableViewController.h"
#import "FGPlotCell.h"
#import "KGNoise.h"
#import "UIBarButtonItem+Customview.h"

@interface FGAnalysisViewController () <PlotViewControllerDelegate, PlotDetailTableViewControllerDelegate, UIPopoverControllerDelegate, NSFetchedResultsControllerDelegate>

@property (nonatomic, strong) FCSFile *fcsFile;
@property (nonatomic, strong) FGPlot *presentedPlot;
@property (nonatomic, strong) UIPopoverController *detailPopoverController;
@property (strong, nonatomic) UIPopoverController *masterPopoverController;

@end

@implementation FGAnalysisViewController

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



- (void)showAnalysis:(FGAnalysis *)analysis
{
    if (!analysis || (_analysis == analysis)) return;
    
    self.analysis = analysis;
    self.title = self.analysis.name;
    if (self.analysis.plots.count == 0 || self.analysis.plots == nil) {
        [FGPlot createRootPlotForAnalysis:self.analysis];
    }
    NSLog(@"will load FCS-file: %@", self);
    [self.collectionView reloadData];
    [self _reloadFCSFile];
}

- (void)_reloadFCSFile
{
    [self.fcsFile cleanUpEvents];
    if (!self.analysis.measurement.fullFilePath) {
        NSLog(@"Error: no file path for measurement: %@", self.analysis.measurement);
        return;
    }
    NSError *error;
    self.fcsFile = [FCSFile fcsFileWithPath:self.analysis.measurement.fullFilePath error:&error];
    if (self.fcsFile == nil) NSLog(@"Error reloading FCS file: %@", error.localizedDescription);
}


- (UICollectionViewCell *)cellForPlot:(FGPlot *)plot
{
    NSUInteger row = [self.analysis.plots indexOfObject:plot] ;
    return [self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:row inSection:0]];
}


- (void)configureCell:(UICollectionViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    FGPlot *plot = [self.analysis.plots objectAtIndex:indexPath.row];
    FGPlotCell *plotCell = (FGPlotCell *)cell;
    if (plot == self.presentedPlot) {
//        [plotCell setHidden:YES];
        return;
    } else {
//        [plotCell setHidden:NO];
    }
    FGGate *parentGate = (FGGate *)plot.parentNode;
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
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    NSLog(@"self.analysis: %@ plots.count: %d", self.analysis.name, self.analysis.plots.count);
    return self.analysis.plots.count;
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
    plotTVC.plot = [self.analysis.plots objectAtIndex:indexPath.row];
    if (self.detailPopoverController.isPopoverVisible) {
        UINavigationController *navCon = (UINavigationController *)self.detailPopoverController.contentViewController;
        [self.detailPopoverController dismissPopoverAnimated:YES];
        if ([navCon.topViewController isKindOfClass:PlotDetailTableViewController.class]) {
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


- (FCSFile *)fcsFile
{
    if (!_fcsFile) {
        NSError *error;
        _fcsFile = [FCSFile fcsFileWithPath:[DOCUMENTS_DIR stringByAppendingPathComponent:self.analysis.measurement.filename] error:&error];
    }
    return _fcsFile;
}


#define PLOTVIEWSIZE 700
#define NAVIGATION_BAR_HEIGHT 44

- (void)_presentPlot:(FGPlot *)plot
{
    UINavigationController *navigationController = [self.storyboard instantiateViewControllerWithIdentifier:@"plotViewController"];
    FGPlotViewController *plotViewController = (FGPlotViewController *)navigationController.topViewController;
    plotViewController.delegate = self;
    plotViewController.plot = plot;
    navigationController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    navigationController.modalPresentationStyle = UIModalPresentationPageSheet;
    navigationController.navigationBar.translucent = YES;
    [navigationController setNavigationBarHidden:YES animated:NO];
    [self presentViewController:navigationController animated:YES completion:^{
        self.presentedPlot = plot;
        [self.collectionView reloadData];
//        NSUInteger row = [self.analysis.plots indexOfObject:plot];
//        [self.collectionView reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:row inSection:0]]];
    }];
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
        [self.collectionView reloadData];
        if (newPlot) {
            [self _presentPlot:newPlot];
        } else {
            NSLog(@"Error creating new plot for gate: %@", gate);
        }
        NSError *error;
        [newPlot.managedObjectContext save:&error];
        if (!error) NSLog(@"Error saving new plot: %@", newPlot);
    }];
}

- (void)plotViewController:(FGPlotViewController *)plotViewController didTapDoneForPlot:(FGPlot *)plot
{
    [self dismissViewControllerAnimated:YES completion:^{
        self.presentedPlot = nil;
//        NSUInteger row = [self.analysis.plots indexOfObject:plot];
//        [self.collectionView reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:row inSection:0]]];
        [self.collectionView reloadData];
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
            [self.collectionView reloadData];
        }];
    } else {
        [self.detailPopoverController dismissPopoverAnimated:YES];
        [self deletePlot:plotToBeDeleted];
        [self.collectionView reloadData];
    }
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    FGPlot *plot = [self.analysis.plots objectAtIndex:indexPath.row];
    [self _presentPlot:plot];
}



@end
