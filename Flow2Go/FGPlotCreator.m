//
//  FGPlotCreator.m
//  Flow2Go
//
//  Created by Christian Hansen on 07/03/13.
//  Copyright (c) 2013 Christian Hansen. All rights reserved.
//

#import "FGPlotCreator.h"
#import "FGMeasurement+Management.h"
#import "FGAnalysis+Management.h"
#import "FGPlot+Management.h"
#import "FGFCSFile.h"
#import "FGPlotDataCalculator.h"
#import "FGPlotHelper.h"
#import "UIImage+Extensions.h"

@interface FGPlotCreator ()

@property (nonatomic, strong) CPTXYGraph *graph;
@property (nonatomic, strong) CPTXYPlotSpace *plotSpace;
@property (nonatomic) NSInteger xParIndex;
@property (nonatomic) NSInteger yParIndex;
@property (nonatomic, strong) FGFCSFile *fcsFile;
@property (nonatomic, strong) FGPlotDataCalculator *plotData;
@property (nonatomic, strong) FGPlotHelper *plotHelper;

@end


@implementation FGPlotCreator
+ (void)createRootPlotsForMeasurementsWithoutPlotsWithCompletion:(void (^)(void))completion
{
    NSArray *allMeasurements = [FGMeasurement findAll];
    NSMutableArray *needPlots = [NSMutableArray array];
    for (FGMeasurement *aMeasurement in allMeasurements) {
        if (!aMeasurement.thumbImage) {
            [needPlots addObject:aMeasurement];
        }
    }
    __block NSUInteger count = needPlots.count;
    for (FGMeasurement *aMeasurement in needPlots) {
        FGPlotCreator *plotCreator = [[FGPlotCreator alloc] init];
        [plotCreator createRootPlotImageForMeasurement:aMeasurement completion:^(UIImage *plotImage) {
            count -= 1;
            if (count == 0) {
                if (completion) completion();
            }
        }];
    }
}


- (void)createRootPlotImageForMeasurement:(FGMeasurement *)measurement completion:(void (^)(UIImage *plotImage))completion
{
    if (!measurement) {
        if (completion) completion(nil);
        return;
    }
    [self _createAnalysisIfNeeded:measurement];
    FGAnalysis *analysis = measurement.analyses.lastObject;
    [self _createPlotIfNeeded:analysis];
    self.plot = analysis.plots.firstObject;
    [self _loadFCSFileForAnalysis:analysis completion:^{
        if (!self.fcsFile) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSLog(@"Error: FCS file is nil: %s", __PRETTY_FUNCTION__);
                if (completion) completion(nil);
            });
            return;
        }
        [self _createGraphAndConfigurePlotSpace];
        [self _insertScatterPlot];
        [self _reloadPlotDataAndLayout];
        UIImage *bigImage = [UIImage captureLayer:self.graph flipImage:YES];
        [self _cleanUp];
        [UIImage resizeImage:bigImage toSize:CGSizeMake(74, 74) completion:^(UIImage *resizedImage) {
            measurement.thumbImage = resizedImage;
            [UIImage resizeImage:bigImage toSize:CGSizeMake(300, 300) completion:^(UIImage *resizedImage) {
                self.plot.image = resizedImage;
                if (completion) completion(resizedImage);
            }];
        }];
    }];
}


- (void)_createAnalysisIfNeeded:(FGMeasurement *)aMeasurement
{
    FGAnalysis *analysis = aMeasurement.analyses.firstObject;
    if (analysis == nil) {
        analysis = [FGAnalysis createAnalysisForMeasurement:aMeasurement];
        NSError *error;
        if(![analysis.managedObjectContext obtainPermanentIDsForObjects:@[analysis] error:&error]) NSLog(@"Error obtaining perm ID: %@", error.localizedDescription);
    }
}


- (void)_createPlotIfNeeded:(FGAnalysis *)analysis
{
    if (analysis.plots.count == 0 || analysis.plots == nil) [FGPlot createRootPlotForAnalysis:analysis];
}


- (void)_loadFCSFileForAnalysis:(FGAnalysis *)analysis completion:(void(^)(void))completion
{
    [self.fcsFile cleanUpEvents];
    [FGFCSFile readFCSFileAtPath:analysis.measurement.fullFilePath progressDelegate:nil withCompletion:^(NSError *error, FGFCSFile *fcsFile) {
        if (!error) {
            self.fcsFile = fcsFile;
        } else {
            NSLog(@"Error reading fcs-file: %@", error.localizedDescription);
        }
        if (completion) completion();
    }];
}

- (void)_cleanUp
{
    self.plotSpace = nil;
    self.graph = nil;
    [self.plotData cleanUpPlotData];
    [self.fcsFile cleanUpEvents];
}

#define DEFAULT_FRAME_IPAD   CGRectMake(0, 0, 750, 750)
#define DEFAULT_FRAME_IPHONE CGRectMake(0, 0, 320, 320)


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
    self.plotSpace.allowsUserInteraction = YES;
    self.plotSpace.delegate = self;
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

#pragma mark Reloading plot
- (void)_reloadPlotDataAndLayout
{
    [self preparePlotData];
    //    [self _updateAxisTitleButtons];
    [self _configureLineAndSymbol];
    [self _updateAxisAndAxisLabels];
    [self.graph reloadData];
    [self _adjustPlotRangeToFitData];
}


- (void)preparePlotData
{
    _xParIndex = self.plot.xParNumber.integerValue - 1;
    _yParIndex = self.plot.yParNumber.integerValue - 1;
    self.plot.xAxisType = [NSNumber numberWithInteger:[self.fcsFile axisTypeForParameterIndex:self.plot.xParNumber.integerValue - 1]];
    self.plot.yAxisType = [NSNumber numberWithInteger:[self.fcsFile axisTypeForParameterIndex:self.plot.yParNumber.integerValue - 1]];
    
    self.plotData = [FGPlotDataCalculator plotDataForFCSFile:self.fcsFile insidePlot:self.plot subset:nil subsetCount:0];
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
    
    switch (self.plot.xAxisType.integerValue) {
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
    
    if (self.plot.plotType.integerValue == kPlotTypeHistogram) {
        self.plotSpace.yScaleType = CPTScaleTypeLinear;
        y.labelFormatter = linearLabelFormatter;
        return;
    }
    
    switch (self.plot.yAxisType.integerValue) {
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
    
    if (self.plot.plotType.integerValue == kPlotTypeHistogram)
    {
        yRange.location = CPTDecimalFromString([NSString stringWithFormat:@"%f", 0.0]);
        yRange.length = CPTDecimalFromString([NSString stringWithFormat:@"%f", self.plotData.countForMaxBin * 1.1]);
        self.plotSpace.yRange = yRange;
        return;
    }
    yRange.location = CPTDecimalFromString([NSString stringWithFormat:@"%f", self.fcsFile.ranges[_yParIndex].minValue]);
    yRange.length = CPTDecimalFromString([NSString stringWithFormat:@"%f", self.fcsFile.ranges[_yParIndex].maxValue-self.fcsFile.ranges[_yParIndex].minValue]);
    self.plotSpace.yRange = yRange;
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
