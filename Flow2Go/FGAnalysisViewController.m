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

@interface FGAnalysisViewController () <PlotViewControllerDelegate, PlotDetailTableViewControllerDelegate, UIPopoverControllerDelegate, NSFetchedResultsControllerDelegate, FGFCSProgressDelegate>

@property (nonatomic, strong) FGFCSFile *fcsFile;
@property (nonatomic, strong) UIPopoverController *detailPopoverController;
@property (strong, nonatomic) UIPopoverController *masterPopoverController;
@property (nonatomic, strong) MBProgressHUD *progressHUD;

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
    [self.collectionView reloadData];
    [self _reloadFCSFile];
}

- (void)_reloadFCSFile
{
    [self.view addSubview:self.progressHUD];
    [self.progressHUD show:NO];
    [FGFCSFile readFCSFileAtPath:self.analysis.measurement.fullFilePath progressDelegate:self withCompletion:^(NSError *error, FGFCSFile *fcsFile) {
        [self.fcsFile cleanUpEvents];
        if (!error) {
            self.fcsFile = fcsFile;
        } else {
            NSLog(@"Error reading fcs-file: %@", error.localizedDescription);
        }
        [self.progressHUD hide:YES];
    }];
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
    FGPlot *plot = [self.analysis.plots objectAtIndex:indexPath.row];
    FGPlotCell *plotCell = (FGPlotCell *)cell;
    FGGate *parentGate = (FGGate *)plot.parentNode;
    NSUInteger allEvents = self.analysis.measurement.countOfEvents.integerValue;
    if (parentGate) {
        plotCell.nameLabel.text = plot.name;
        plotCell.countLabel.text = [NSString countsAndPercentageAsString:parentGate.cellCount.integerValue ofAll:allEvents];
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


- (FGFCSFile *)fcsFile
{
    if (!_fcsFile) {
        NSError *error;
        _fcsFile = [FGFCSFile fcsFileWithPath:[DOCUMENTS_DIR stringByAppendingPathComponent:self.analysis.measurement.filename] error:&error];
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
    [self presentViewController:navigationController animated:YES completion:^{
        
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
- (FGFCSFile *)fcsFileForPlot:(FGPlot *)plot
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
        if (error) NSLog(@"Error saving new plot: %@", newPlot);
    }];
}

- (void)plotViewController:(FGPlotViewController *)plotViewController didTapDoneForPlot:(FGPlot *)plot
{
    [self dismissViewControllerAnimated:YES completion:^{
        NSUInteger row = [self.analysis.plots indexOfObject:plot];
        [self.collectionView reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:row inSection:0]]];
        NSError *error;
        [plot.managedObjectContext saveToPersistentStoreAndWait];
        if (error) NSLog(@"Error saving plot: %@", error.localizedDescription);
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

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    FGPlot *plot = [self.analysis.plots objectAtIndex:indexPath.row];
    [self _presentPlot:plot];
}



@end
