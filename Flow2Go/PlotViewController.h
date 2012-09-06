//
//  PlotViewController.h
//  Flow2Go
//
//  Created by Christian Hansen on 03/08/12.
//  Copyright (c) 2012 Christian Hansen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CorePlot-CocoaTouch.h"
#import "MarkView.h"

@class Measurement;
@class Plot;
@class Gate;
@class FCSFile;

@protocol PlotViewControllerDelegate <NSObject>
- (FCSFile *)fcsFile:(id)sender;
- (void)didSelectGate:(Gate *)gate forPlot:(Plot *)plot;
- (void)didDeleteGate:(Gate *)gate;

@end

@interface PlotViewController : UIViewController <CPTPlotDataSource, CPTScatterPlotDelegate, CPTScatterPlotDataSource, CPTPlotSpaceDelegate, MarkViewDelegate, UIActionSheetDelegate>

- (void)prepareDataForPlot;

@property (nonatomic, strong) Plot *plot;
@property (nonatomic, weak) IBOutlet CPTGraphHostingView *graphHostingView;
@property (nonatomic, weak) IBOutlet MarkView *markView;
@property (weak, nonatomic) IBOutlet UIButton *xAxisButton;
@property (weak, nonatomic) IBOutlet UIButton *yAxisButton;
@property (weak, nonatomic) id<PlotViewControllerDelegate> delegate;

@end
