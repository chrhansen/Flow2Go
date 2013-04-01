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

@property (nonatomic, strong) FGGraph *graph;
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
    plotCreator.plotOptions = plotOptions;
    
    CGRect rect = (IS_IPAD) ? DEFAULT_FRAME_IPAD : DEFAULT_FRAME_IPHONE;
    plotCreator.graph = [[FGGraph alloc] initWithFrame:rect themeNamed:kCPTSlateTheme];
    plotCreator.graph.dataSource = plotCreator;
    [plotCreator preparePlotData];

    [plotCreator _updateLayout];
    UIImage *bigImage = [UIImage captureLayer:plotCreator.graph flipImage:YES];
    plotCreator.plotImage = [UIImage scaleImage:bigImage toSize:CGSizeMake(300, 300)];
    plotCreator.thumbImage = [UIImage scaleImage:bigImage toSize:CGSizeMake(74, 74)];
    
    return plotCreator;
}


- (void)dealloc
{
    if (_parentSubSet) free(_parentSubSet);
}


- (void)_updateLayout
{
    FGPlotType plotType = [self.plotOptions[PlotType] integerValue];
    NSInteger xParIndex = [self.plotOptions[XParNumber] integerValue] - 1;
    NSInteger yParIndex = [self.plotOptions[YParNumber] integerValue] - 1;
    [self.graph configureStyleForPlotType:plotType];
    [self.graph updateXAxis:[self.plotOptions[XAxisType] integerValue] yAxisType:[self.plotOptions[YAxisType] integerValue] plotType:plotType];
    [self.graph reloadData];
    [self.graph adjustPlotRangeToFitXRange:self.fcsFile.ranges[xParIndex] yRange:self.fcsFile.ranges[yParIndex] plotType:plotType];
}


- (void)preparePlotData
{
    self.plotData = [FGPlotDataCalculator plotDataForFCSFile:self.fcsFile plotOptions:self.plotOptions subset:self.parentSubSet subsetCount:self.parentSubSetCount];
}


#pragma mark - FG Graph Data Source
- (NSInteger)countForHistogramMaxValue
{
    return self.plotData.countForMaxBin;
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
