//
//  FCSGraphView.h
//  Flow2Go
//
//  Created by Christian Hansen on 12/08/12.
//  Copyright (c) 2012 Christian Hansen. All rights reserved.
//

#import "CorePlot-CocoaTouch.h"
#import "CPTGraphHostingView.h"
#import "CPTGraph.h"

@interface FCSGraphView : UIView

@property (nonatomic, strong) CPTXYGraph *graph;
@property (nonatomic, weak) id<CPTPlotDataSource, CPTScatterPlotDelegate, CPTScatterPlotDataSource, CPTPlotSpaceDelegate> delegate;

@end
