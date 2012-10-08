//
//  PlotViewController.h
//  Flow2Go
//
//  Created by Christian Hansen on 03/08/12.
//  Copyright (c) 2012 Christian Hansen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CorePlot-CocoaTouch.h"
#import "GatesContainerView.h"

@class Measurement;
@class Plot;
@class Gate;
@class FCSFile;
@class PlotViewController;

@protocol PlotViewControllerDelegate <NSObject>
- (FCSFile *)fcsFileForPlot:(Plot *)plot;
- (void)plotViewController:(PlotViewController *)plotViewController didSelectGate:(Gate *)gate forPlot:(Plot *)plot;
- (void)plotViewController:(PlotViewController *)plotViewController didDeleteGate:(Gate *)gate;
- (void)plotViewController:(PlotViewController *)plotViewController didTapDoneForPlot:(Plot *)plot;

@end

@interface PlotViewController : UIViewController <CPTPlotDataSource, CPTScatterPlotDelegate, CPTScatterPlotDataSource, CPTPlotSpaceDelegate, GatesContainerViewDelegate, UIActionSheetDelegate>

- (void)preparePlotData;

@property (nonatomic, strong) Plot *plot;
@property (nonatomic, weak) IBOutlet CPTGraphHostingView *graphHostingView;
@property (nonatomic, weak) IBOutlet GatesContainerView *gatesContainerView;
@property (weak, nonatomic) IBOutlet UIButton *xAxisButton;
@property (weak, nonatomic) IBOutlet UIButton *yAxisButton;
@property (weak, nonatomic) id<PlotViewControllerDelegate> delegate;

@end
