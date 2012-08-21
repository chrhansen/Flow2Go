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
#import "Cell.h"
#import "Plot.h"
#import "Gate.h"
#import "PinchLayout.h"

@interface AnalysisViewController ()

@property (nonatomic, strong) Analysis *analysis;

@end

@implementation AnalysisViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    UIPinchGestureRecognizer* pinchRecognizer = [UIPinchGestureRecognizer.alloc initWithTarget:self
                                                                                        action:@selector(handlePinchGesture:)];
    [self.collectionView addGestureRecognizer:pinchRecognizer];
    [self.collectionView registerClass:Cell.class forCellWithReuseIdentifier:@"Plot Cell"];
    
    self.navigationItem.rightBarButtonItem = [UIBarButtonItem.alloc initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                         target:self
                                                                                         action:@selector(doneTapped)];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)configureCell:(Cell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    Plot *plot = [self.analysis.plots objectAtIndex:indexPath.row];
    cell.label.text = [plot.parentNode valueForKey:@"name"];
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"Show Plot"])
    {
        //
    }
}


- (void)showAnalysis:(Analysis *)analysis forMeasurement:(Measurement *)measurement
{
    //TODO: define what show analysis requires - read the file again? Just show plot thumbnails?
    self.analysis = analysis;
    if (self.analysis.plots.count == 0)
    {
        [self.analysis createRootPlot];
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

#pragma mark - Collection View Data source
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.analysis.plots.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    Cell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Plot Cell"
                                                           forIndexPath:indexPath];
    [self configureCell:cell atIndexPath:indexPath];
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    Plot *plot = [self.analysis.plots objectAtIndex:indexPath.row];
    
    UINavigationController *navigationController = [self.storyboard instantiateViewControllerWithIdentifier:@"plotViewController"];
    PlotViewController *plotViewController = (PlotViewController *)navigationController.topViewController;
    [self presentViewController:navigationController animated:YES completion:nil];
    
    [plotViewController showPlot:plot forMeasurement:self.analysis.measurement];
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
