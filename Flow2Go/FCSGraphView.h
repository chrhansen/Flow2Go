//
//  FCSGraphView.h
//  Flow2Go
//
//  Created by Christian Hansen on 12/08/12.
//  Copyright (c) 2012 Christian Hansen. All rights reserved.
//

#import "CPTGraphHostingView.h"
#import "CorePlot-CocoaTouch.h"
#import "CPTGraph.h"

@interface FCSGraphView : UIView

@property (nonatomic, strong) CPTXYGraph *graph;
@property (nonatomic, weak) id<CPTPlotDataSource, CPTScatterPlotDelegate, CPTScatterPlotDataSource, CPTPlotSpaceDelegate> delegate;

@end
