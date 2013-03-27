//
//  FGPlotCreator.m
//  Flow2Go
//
//  Created by Christian Hansen on 27/03/13.
//  Copyright (c) 2013 Christian Hansen. All rights reserved.
//

#import "FGPlotCreator.h"
#import "FGPlotHelper.h"
#import "FGPlotDataCalculator.h"
#import "FGFCSFile.h"
#import "UIImage+Extensions.h"

@interface FGPlotCreator ()

@property (nonatomic, strong) CPTXYGraph *graph;
@property (nonatomic, strong) CPTXYPlotSpace *plotSpace;
@property (nonatomic) NSInteger xParIndex;
@property (nonatomic) NSInteger yParIndex;
@property (nonatomic) FGAxisType xAxisType;
@property (nonatomic) FGAxisType yAxisType;
@property (nonatomic) FGPlotType plotType;
@property (nonatomic, strong) FGFCSFile *fcsFile;
@property (nonatomic, strong) FGPlotDataCalculator *plotData;
@property (nonatomic) NSUInteger *parentSubSet;
@property (nonatomic) NSUInteger parentSubSetCount;
@property (nonatomic, strong) FGPlotHelper *plotHelper;
@property (nonatomic, strong) NSDictionary *plotOptions;

@end

@implementation FGPlotCreator


+ (FGPlotCreator *)renderPlotImageWithPlotOptions:(NSDictionary *)plotOptions
                                          fcsFile:(FGFCSFile *)fcsFile
                                     parentSubSet:(NSUInteger *)parentSubSet
                                parentSubSetCount:(NSUInteger)parentSubSetCount
{
    if (!plotOptions || !fcsFile) {
        return nil;
    }
    FGPlotCreator *plotCreator = [[FGPlotCreator alloc] init];
    
    plotCreator.parentSubSet      = parentSubSet;
    plotCreator.parentSubSetCount = parentSubSetCount;
    plotCreator.fcsFile = fcsFile;
    [plotCreator _initializePlotOptions:plotOptions];
    [plotCreator _createGraphAndConfigurePlotSpace];
    [plotCreator _insertScatterPlot];
    [plotCreator _reloadPlotDataAndLayout];
    UIImage *bigImage = [UIImage captureLayer:plotCreator.graph flipImage:YES];
    
    NSData *binaryImageData = UIImagePNGRepresentation(bigImage);
    [binaryImageData writeToFile:[TEMP_DIR stringByAppendingPathComponent:[[NSDate date] description]] atomically:YES];
    
    [plotCreator _cleanUp];
    plotCreator.plotImage = [UIImage scaleImage:bigImage toSize:CGSizeMake(300, 300)];
    plotCreator.thumbImage = [UIImage scaleImage:bigImage toSize:CGSizeMake(74, 74)];
    
    return plotCreator;
}


- (void)dealloc
{
    if (_parentSubSet) free(_parentSubSet);
}


- (void)_initializePlotOptions:(NSDictionary *)plotOptions
{
    self.plotOptions = plotOptions;
    _xAxisType = [plotOptions[XAxisType] integerValue];
    _yAxisType = [plotOptions[YAxisType] integerValue];
    _xParIndex = [plotOptions[XParNumber] integerValue] - 1;
    _yParIndex = [plotOptions[YParNumber] integerValue] - 1;
}



- (void)_createGraphAndConfigurePlotSpace
{
    CGRect rect = (IS_IPAD) ? DEFAULT_FRAME_IPAD : DEFAULT_FRAME_IPHONE;
    self.graph = [CPTXYGraph.alloc initWithFrame:rect];
    [self.graph applyTheme:[CPTTheme themeNamed:kCPTSlateTheme]];
    self.graph.paddingLeft = 0.0f;
    self.graph.paddingRight = 0.0f;
    self.graph.paddingTop = 0.0f;
    self.graph.paddingBottom = 0.0f;
    self.graph.plotAreaFrame.paddingLeft = 100.0;
    self.graph.plotAreaFrame.paddingRight = 20.0;
    self.graph.plotAreaFrame.paddingBottom = 70.0;
    self.graph.plotAreaFrame.paddingTop = 40.0;
    self.graph.plotAreaFrame.borderLineStyle = nil;
    
    self.plotSpace = (CPTXYPlotSpace *)self.graph.defaultPlotSpace;
//    self.plotSpace.allowsUserInteraction = YES;
//    self.plotSpace.delegate = self;
}


- (void)_insertScatterPlot
{
    CPTScatterPlot *scatterPlot = [CPTScatterPlot.alloc init];
    scatterPlot.dataSource = self;
    scatterPlot.delegate = self;
    scatterPlot.identifier = @"Scatter Plot 1";
    scatterPlot.plotSymbolMarginForHitDetection = 5.0;
    scatterPlot.borderWidth = 2.0f;
    scatterPlot.borderColor = [self _currentThemeLineColor];
    
    [self.graph addPlot:scatterPlot toPlotSpace:self.graph.defaultPlotSpace];
}

- (CGColorRef)_currentThemeLineColor
{
    CPTXYAxisSet *axisSet = (CPTXYAxisSet *)self.graph.axisSet;
    return axisSet.xAxis.majorTickLineStyle.lineColor.cgColor;
}


- (void)_reloadPlotDataAndLayout
{
    [self preparePlotData];
    [self _configureLineAndSymbol];
    [self _updateAxisAndAxisLabels];
    [self.graph reloadData];
    [self _adjustPlotRangeToFitData];
}


- (void)preparePlotData
{
    self.plotData = [FGPlotDataCalculator plotDataForFCSFile:self.fcsFile plotOptions:self.plotOptions subset:self.parentSubSet subsetCount:self.parentSubSetCount];
}

- (void)_configureLineAndSymbol
{
    CPTScatterPlot *scatterPlot = (CPTScatterPlot *)[self.graph plotWithIdentifier:@"Scatter Plot 1"];
    scatterPlot.dataLineStyle = nil;
    scatterPlot.plotSymbol = nil;
    scatterPlot.areaFill = nil;
}


- (void)_updateAxisAndAxisLabels
{
    CPTXYAxisSet *axisSet = (CPTXYAxisSet *)self.graph.axisSet;
    CPTXYAxis *x = axisSet.xAxis;
    CPTXYAxis *y = axisSet.yAxis;
    CPTColor *themeColor = [CPTColor colorWithCGColor:[self _currentThemeLineColor]];
    
    NSNumberFormatter *logarithmicLabelFormatter = NSNumberFormatter.alloc.init;
    [logarithmicLabelFormatter setGeneratesDecimalNumbers:NO];
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
    
    switch (_xAxisType) {
        case kAxisTypeLinear:
            self.plotSpace.xScaleType = CPTScaleTypeLinear;
            x.labelFormatter = linearLabelFormatter;
            break;
            
        case kAxisTypeLogarithmic:
            self.plotSpace.xScaleType = CPTScaleTypeLog;
            x.labelFormatter = logarithmicLabelFormatter;
            break;
            
        default:
            break;
    }
    
    if (_plotType == kPlotTypeHistogram) {
        self.plotSpace.yScaleType = CPTScaleTypeLinear;
        y.labelFormatter = linearLabelFormatter;
        return;
    }
    
    switch (_yAxisType) {
        case kAxisTypeLinear:
            self.plotSpace.yScaleType = CPTScaleTypeLinear;
            y.labelFormatter = linearLabelFormatter;
            break;
            
        case kAxisTypeLogarithmic:
            self.plotSpace.yScaleType = CPTScaleTypeLog;
            y.labelFormatter = logarithmicLabelFormatter;
            break;
            
        default:
            break;
    }
}


- (void)_adjustPlotRangeToFitData
{
    CPTMutablePlotRange *xRange = [self.plotSpace.xRange mutableCopy];
    xRange.location = CPTDecimalFromString([NSString stringWithFormat:@"%f", self.fcsFile.ranges[_xParIndex].minValue]);
    xRange.length = CPTDecimalFromString([NSString stringWithFormat:@"%f", self.fcsFile.ranges[_xParIndex].maxValue-self.fcsFile.ranges[_xParIndex].minValue]);
    self.plotSpace.xRange = xRange;
    
    CPTMutablePlotRange *yRange = [self.plotSpace.yRange mutableCopy];
    
    if (_plotType == kPlotTypeHistogram) {
        yRange.location = CPTDecimalFromString([NSString stringWithFormat:@"%f", 0.0]);
        yRange.length = CPTDecimalFromString([NSString stringWithFormat:@"%f", self.plotData.countForMaxBin * 1.2]);
        self.plotSpace.yRange = yRange;
    } else {
        yRange.location = CPTDecimalFromString([NSString stringWithFormat:@"%f", self.fcsFile.ranges[_yParIndex].minValue]);
        yRange.length = CPTDecimalFromString([NSString stringWithFormat:@"%f", self.fcsFile.ranges[_yParIndex].maxValue-self.fcsFile.ranges[_yParIndex].minValue]);
        self.plotSpace.yRange = yRange;
    }
}

- (void)_cleanUp
{
    self.plotSpace = nil;
    self.graph = nil;
    [self.plotData cleanUpPlotData];
    [self.fcsFile cleanUpEvents];
}

#pragma mark - CPT Plot Data Source
- (NSUInteger)numberOfRecordsForPlot:(CPTPlot *)plot
{
    return self.fcsFile.noOfEvents;
}


- (double)doubleForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index
{
    switch (fieldEnum) {
        case CPTCoordinateX:
            return self.plotData.points[index].xVal;
            break;
            
        case CPTCoordinateY:
            return self.plotData.points[index].yVal;
            break;
            
        default:
            break;
    }
    return 0.0;
}

#pragma mark - Scatter Plot Delegate
#define COLOR_LEVELS 15
#define PLOTSYMBOL_SIZE 2.0

#pragma mark - Scatter Plot Datasource
-(CPTPlotSymbol *)symbolForScatterPlot:(CPTScatterPlot *)plot recordIndex:(NSUInteger)index
{
    if (!_plotHelper) {
        _plotHelper = [FGPlotHelper coloredPlotSymbols:COLOR_LEVELS ofSize:CGSizeMake(PLOTSYMBOL_SIZE, PLOTSYMBOL_SIZE)];
    }
    NSInteger cellCount = _plotData.points[index].count;
    if (cellCount > 0) {
        NSInteger colorLevel = COLOR_LEVELS * (float)cellCount / (float)_plotData.countForMaxBin;
        if (colorLevel > -1
            && colorLevel < COLOR_LEVELS) {
            return _plotHelper.plotSymbols[colorLevel];
        }
    }
    return nil;
}

@end
