//
//  FGGraph.m
//  Flow2Go
//
//  Created by Christian Hansen on 01/04/13.
//  Copyright (c) 2013 Christian Hansen. All rights reserved.
//

#import "FGGraph.h"
#import "FGPlot+Management.h"

@implementation FGGraph


- (id)initWithFrame:(CGRect)frame themeNamed:(NSString *)themeName
{
    self = [super initWithFrame:frame];
    if (self) {
        if (!themeName) themeName = kCPTSlateTheme;
        [self applyTheme:[CPTTheme themeNamed:themeName]];
        [self _configurePlotSpace];
        [self _insertScatterPlot];
    }
    return self;
}


- (void)setDataSource:(id<FGGraphDataSource>)dataSource
{
    if (dataSource != _dataSource) {
        _dataSource = dataSource;
        CPTScatterPlot *scatterPlot = (CPTScatterPlot *)[self plotWithIdentifier:@"Scatter Plot 1"];
        scatterPlot.dataSource = dataSource;
    }
}

- (void)updateGraphWithPlotOptions:(NSDictionary *)plotOptions
{
    FGPlotType *plotType = [plotOptions[PlotType] integerValue];
    FGAxisType *xAxisType = [plotOptions[XAxisType] integerValue];
    FGAxisType *yAxisType = [plotOptions[YAxisType] integerValue];
    [self configureStyleForPlotType:plotType];
    [self updateXAxis:xAxisType yAxisType:yAxisType plotType:plotType];
}



- (void)configureStyleForPlotType:(FGPlotType)plotType
{
    CPTScatterPlot *scatterPlot = (CPTScatterPlot *)[self plotWithIdentifier:@"Scatter Plot 1"];
    
    if (plotType == kPlotTypeDot
        || plotType == kPlotTypeDensity) {
        scatterPlot.dataLineStyle = nil;
        scatterPlot.plotSymbol = nil;
        scatterPlot.areaFill = nil;
    } else if (plotType == kPlotTypeHistogram) {
        CPTMutableLineStyle *histogramLineStyle = [CPTMutableLineStyle lineStyle];
        histogramLineStyle.lineWidth = 1.5;
        CPTColor *lineColor = [CPTColor blackColor];
        histogramLineStyle.lineColor = [CPTColor blackColor];
        scatterPlot.dataLineStyle = histogramLineStyle;
        CPTMutableLineStyle *histogramSymbolLineStyle = [CPTMutableLineStyle lineStyle];
        histogramSymbolLineStyle.lineColor = lineColor;
        scatterPlot.interpolation = CPTScatterPlotInterpolationCurved;
        CPTFill *areaGradientFill = [CPTFill fillWithColor:[[CPTColor colorWithCGColor:[self _currentThemeLineColor]] colorWithAlphaComponent:0.2f]];
        scatterPlot.areaFill      = areaGradientFill;
        scatterPlot.areaBaseValue = [[NSDecimalNumber zero] decimalValue];
    }
}


- (void)_configurePlotSpace
{
    self.paddingLeft = 0.0f;
    self.paddingRight = 0.0f;
    self.paddingTop = 0.0f;
    self.paddingBottom = 0.0f;
    self.plotAreaFrame.paddingLeft = 100.0;
    self.plotAreaFrame.paddingRight = 20.0;
    self.plotAreaFrame.paddingBottom = 100.0;
    self.plotAreaFrame.paddingTop = 20.0;
    self.plotAreaFrame.borderLineStyle = nil;
    
    CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)self.defaultPlotSpace;
    plotSpace.allowsUserInteraction = YES;
}


- (void)_insertScatterPlot
{
    CPTScatterPlot *scatterPlot = [CPTScatterPlot.alloc init];
    scatterPlot.dataSource = self.dataSource;
    scatterPlot.identifier = @"Scatter Plot 1";
    scatterPlot.plotSymbolMarginForHitDetection = 5.0;
    scatterPlot.borderWidth = 2.0f;
    scatterPlot.borderColor = [self _currentThemeLineColor];
    [self addPlot:scatterPlot toPlotSpace:self.defaultPlotSpace];
}

- (CGColorRef)_currentThemeLineColor
{
    CPTXYAxisSet *axisSet = (CPTXYAxisSet *)self.axisSet;
    return axisSet.xAxis.majorTickLineStyle.lineColor.cgColor;
}



- (void)updateXAxis:(FGAxisType)xAxisType yAxisType:(FGAxisType)yAxisType plotType:(FGPlotType)plotType
{
    CPTXYAxisSet *axisSet = (CPTXYAxisSet *)self.axisSet;
    CPTXYAxis *x = axisSet.xAxis;
    CPTXYAxis *y = axisSet.yAxis;
    CPTColor *themeColor = [CPTColor colorWithCGColor:[self _currentThemeLineColor]];
    
    NSNumberFormatter *logarithmicLabelFormatter = NSNumberFormatter.alloc.init;
    [logarithmicLabelFormatter setGeneratesDecimalNumbers:NO];
    //[logarithmicLabelFormatter setNumberStyle:kCFNumberFormatterScientificStyle];
    [logarithmicLabelFormatter setNumberStyle:kCFNumberFormatterDecimalStyle];
    [logarithmicLabelFormatter setExponentSymbol:@"e"];
    
    NSNumberFormatter *linearLabelFormatter = NSNumberFormatter.alloc.init;
    [linearLabelFormatter setGeneratesDecimalNumbers:NO];
    [linearLabelFormatter setNumberStyle:kCFNumberFormatterDecimalStyle];
    
    CPTMutableLineStyle *minorTickLineStyle = [x.minorTickLineStyle mutableCopy];
    minorTickLineStyle.lineColor = themeColor;
    
    CPTMutableTextStyle *labelTextStyle = [x.labelTextStyle mutableCopy];
    labelTextStyle.color = themeColor;
    x.labelingPolicy = CPTAxisLabelingPolicyAutomatic;
    x.preferredNumberOfMajorTicks = 10;
    x.minorTickLineStyle = minorTickLineStyle;
    x.tickDirection = CPTSignNegative;
    x.labelTextStyle = labelTextStyle;
    x.axisLineStyle = nil;
    
    
    y.labelingPolicy = CPTAxisLabelingPolicyAutomatic;
    y.preferredNumberOfMajorTicks = 10;
    y.minorTickLineStyle = minorTickLineStyle;
    y.tickDirection = CPTSignNegative;
    y.labelTextStyle = labelTextStyle;
    y.axisLineStyle = nil;
    
    x.orthogonalCoordinateDecimal = CPTDecimalFromString(@"0");
    x.title = nil;
    x.axisConstraints = [CPTConstraints constraintWithLowerOffset:0.0f];
    
    y.orthogonalCoordinateDecimal = CPTDecimalFromString(@"0");
    y.title = nil;
    y.axisConstraints = [CPTConstraints constraintWithLowerOffset:0.0f];
    
    CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)self.defaultPlotSpace;

    switch (xAxisType) {
        case kAxisTypeLinear:
            plotSpace.xScaleType = CPTScaleTypeLinear;
            x.labelFormatter = linearLabelFormatter;
            break;
            
        case kAxisTypeLogarithmic:
            plotSpace.xScaleType = CPTScaleTypeLog;
            x.labelFormatter = logarithmicLabelFormatter;
            break;
            
        default:
            break;
    }
    
    if (plotType == kPlotTypeHistogram) {
        plotSpace.yScaleType = CPTScaleTypeLinear;
        y.labelFormatter = linearLabelFormatter;
        return;
    }
    
    switch (yAxisType) {
        case kAxisTypeLinear:
            plotSpace.yScaleType = CPTScaleTypeLinear;
            y.labelFormatter = linearLabelFormatter;
            break;
            
        case kAxisTypeLogarithmic:
            plotSpace.yScaleType = CPTScaleTypeLog;
            y.labelFormatter = logarithmicLabelFormatter;
            break;
            
        default:
            break;
    }
}


- (void)adjustPlotRangeToFitXRange:(FGRange)xMinMaxRange yRange:(FGRange)yMinMaxRange plotType:(FGPlotType)plotType
{
    CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)self.defaultPlotSpace;
    CPTMutablePlotRange *xRange = [plotSpace.xRange mutableCopy];
    xRange.location = CPTDecimalFromString([NSString stringWithFormat:@"%f", xMinMaxRange.minValue]);
    xRange.length = CPTDecimalFromString([NSString stringWithFormat:@"%f", xMinMaxRange.maxValue - xMinMaxRange.minValue]);
    plotSpace.xRange = xRange;
    
    CPTMutablePlotRange *yRange = [plotSpace.yRange mutableCopy];
    
    if (plotType == kPlotTypeHistogram) {
        yRange.location = CPTDecimalFromString([NSString stringWithFormat:@"%f", 0.0]);
        NSInteger maxCount = [self.dataSource countForHistogramMaxValue];
        yRange.length = CPTDecimalFromString([NSString stringWithFormat:@"%f", (double)maxCount * 1.1]);
        plotSpace.yRange = yRange;
        return;
    }
    yRange.location = CPTDecimalFromString([NSString stringWithFormat:@"%f", yMinMaxRange.minValue]);
    yRange.length = CPTDecimalFromString([NSString stringWithFormat:@"%f", yMinMaxRange.maxValue - yMinMaxRange.minValue]);
    plotSpace.yRange = yRange;
}
@end
