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

@class FGMeasurement;
@class FGPlot;
@class FGGate;
@class FGFCSFile;
@class FGPlotViewController;

@protocol PlotViewControllerDelegate <NSObject>
- (FGFCSFile *)fcsFileForPlot:(FGPlot *)plot;
- (void)plotViewController:(FGPlotViewController *)plotViewController didSelectGate:(FGGate *)gate forPlot:(FGPlot *)plot;
- (void)plotViewController:(FGPlotViewController *)plotViewController didTapDoneForPlot:(FGPlot *)plot;

@end

@interface FGPlotViewController : UIViewController <CPTPlotDataSource, CPTScatterPlotDelegate, CPTScatterPlotDataSource, CPTPlotSpaceDelegate, GatesContainerViewDelegate, UIActionSheetDelegate>

- (void)preparePlotData;

@property (nonatomic, strong) FGPlot *plot;
@property (nonatomic, weak) IBOutlet CPTGraphHostingView *graphHostingView;
@property (nonatomic, weak) IBOutlet FGGatesContainerView *gatesContainerView;
@property (weak, nonatomic) IBOutlet UIButton *xAxisButton;
@property (weak, nonatomic) IBOutlet UIButton *yAxisButton;
@property (weak, nonatomic) id<PlotViewControllerDelegate> delegate;

@end
