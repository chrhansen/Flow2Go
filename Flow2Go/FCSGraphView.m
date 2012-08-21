//
//  FCSGraphView.m
//  Flow2Go
//
//  Created by Christian Hansen on 12/08/12.
//  Copyright (c) 2012 Christian Hansen. All rights reserved.
//

#import "FCSGraphView.h"

@interface FCSGraphView ()

@property (nonatomic, strong) CPTXYPlotSpace *plotSpace;

@end

@implementation FCSGraphView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        CPTXYGraph *graph = [CPTXYGraph.alloc initWithFrame:frame];
        CPTTheme *theme = [CPTTheme themeNamed:kCPTDarkGradientTheme];
        [graph applyTheme:theme];
        graph.delegate = self.delegate;
         
        
        CPTGraphHostingView *newHostingView = [CPTGraphHostingView.alloc initWithFrame:frame];
        newHostingView.hostedGraph = _graph;
        [self addSubview:newHostingView];
        
        [self _insertScatterPlot];
    }
    return self;
}


- (void)_insertScatterPlot
{
    // Add plot space for horizontal bar charts
    self.plotSpace = (CPTXYPlotSpace *)self.graph.defaultPlotSpace;
    self.plotSpace.xRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromInteger(0) length:CPTDecimalFromInteger(1024)];
    self.plotSpace.yRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromInteger(0) length:CPTDecimalFromInteger(1024)];
    self.plotSpace.allowsUserInteraction = YES;
    self.plotSpace.delegate = self.delegate;
    
    CPTXYAxisSet *axisSet = (CPTXYAxisSet *)self.graph.axisSet;
    CPTXYAxis *x = axisSet.xAxis;
    x.axisLineStyle = nil;
    x.majorTickLineStyle = nil;
    x.minorTickLineStyle = nil;
    x.majorIntervalLength = CPTDecimalFromString(@"200");
    x.orthogonalCoordinateDecimal = CPTDecimalFromString(@"0");
    x.title = @"";
    x.titleOffset = 45.0f;
    x.titleLocation = CPTDecimalFromFloat(500.0f);
    x.labelRotation = M_PI/4;
    x.axisConstraints = [CPTConstraints constraintWithLowerOffset:45.0f];
    
    CPTXYAxis *y = axisSet.yAxis;
    y.axisLineStyle = nil;
    y.majorTickLineStyle = nil;
    y.minorTickLineStyle = nil;
    y.majorIntervalLength = CPTDecimalFromString(@"200");
    y.orthogonalCoordinateDecimal = CPTDecimalFromString(@"0");
    y.title = @"";
    y.titleOffset = 45.0f;
    y.titleLocation = CPTDecimalFromFloat(500.0f);
    y.axisConstraints = [CPTConstraints constraintWithLowerOffset:45.0f];
    
    
    CPTScatterPlot *scatterPlot = [[CPTScatterPlot alloc] init];
    scatterPlot.dataSource = self.delegate;
    scatterPlot.delegate = self.delegate;
    scatterPlot.identifier = @"Scatter Plot 1";
    scatterPlot.dataLineStyle = nil;
    scatterPlot.plotSymbolMarginForHitDetection = 5.0;
    
    [self.graph addPlot:scatterPlot toPlotSpace:self.plotSpace];
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
