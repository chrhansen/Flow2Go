//
//  PlotViewController.h
//  Flow2Go
//
//  Created by Christian Hansen on 03/08/12.
//  Copyright (c) 2012 Christian Hansen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CorePlot-CocoaTouch.h"
#import "FGGatesContainerView.h"
#import "FGAddGateButtonsView.h"
#import "FGGraph.h"

@class FGMeasurement;
@class FGPlot;
@class FGGate;
@class FGFCSFile;
@class FGPlotViewController;
@class FGGateCalculator;

@protocol PlotViewControllerDelegate <NSObject>

- (FGFCSFile *)fcsFileForPlot:(FGPlot *)plot;
- (void)plotViewController:(FGPlotViewController *)plotViewController didRequestNewPlotWithPopulationInGate:(FGGate *)gate;
- (void)plotViewController:(FGPlotViewController *)plotViewController didTapDoneForPlot:(FGPlot *)plot;

@end

@interface FGPlotViewController : UIViewController <CPTScatterPlotDataSource, GatesContainerViewDelegate>

- (void)updatePlotData;

// get the subset currently shown in the plot
- (FGGateCalculator *)displayedSubset;
// set subset inherited from another plot or set to nil for root plots
- (void)setDisplayedSubset:(FGGateCalculator *)gateCalculator;

- (void)clearPlotData;


@property (nonatomic, strong) FGPlot *plot;
@property (nonatomic, weak) IBOutlet CPTGraphHostingView *graphHostingView;
@property (nonatomic, weak) IBOutlet FGGatesContainerView *gatesContainerView;
@property (nonatomic, weak) IBOutlet FGAddGateButtonsView *addGateButtonsView;
@property (weak, nonatomic) IBOutlet UIButton *xAxisButton;
@property (weak, nonatomic) IBOutlet UIButton *yAxisButton;
@property (weak, nonatomic) id<PlotViewControllerDelegate> delegate;
@property (nonatomic, strong) FGGraph *graph;

@end
