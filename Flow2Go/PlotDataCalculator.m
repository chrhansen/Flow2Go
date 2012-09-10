//
//  DensityPlotData.m
//  Flow2Go
//
//  Created by Christian Hansen on 29/08/12.
//  Copyright (c) 2012 Christian Hansen. All rights reserved.
//

#import "PlotDataCalculator.h"
#import "FCSFile.h"
#import "Measurement.h"
#import "Analysis.h"
#import "Plot.h"
#import "Keyword.h"

@implementation PlotDataCalculator

#define BIN_COUNT 512
#define HISTOGRAM_COUNT 256

+ (PlotDataCalculator *)plotDataForFCSFile:(FCSFile *)fcsFile
                                insidePlot:(Plot *)plot
                                    subset:(NSUInteger *)subset
                               subsetCount:(NSUInteger)subsetCount
{
    switch (plot.plotType.integerValue)
    {
        case kPlotTypeDot:
            return [PlotDataCalculator dotDataForFCSFile:fcsFile insidePlot:plot subset:subset subsetCount:subsetCount];
            break;
            
        case kPlotTypeDensity:
            return [PlotDataCalculator densityDataForFCSFile:fcsFile insidePlot:plot subset:subset subsetCount:subsetCount];
            break;
            
        case kPlotTypeHistogram:
            return [PlotDataCalculator histogramForFCSFile:fcsFile insidePlot:plot subset:subset subsetCount:subsetCount];
            break;
            
        default:
            break;
    }
    return nil;
}



+ (PlotDataCalculator *)dotDataForFCSFile:(FCSFile *)fcsFile
                               insidePlot:(Plot *)plot
                                   subset:(NSUInteger *)subset
                              subsetCount:(NSUInteger)subsetCount
{  
    PlotDataCalculator *dotPlotData = [PlotDataCalculator.alloc init];
    NSInteger eventsInside = fcsFile.noOfEvents;

    if (subset)
    {
        eventsInside = subsetCount;
    }
    
    NSInteger xPar = plot.xParNumber.integerValue - 1;
    NSInteger yPar = plot.yParNumber.integerValue - 1;
    dotPlotData.points = calloc(eventsInside, sizeof(DensityPoint));
    dotPlotData.numberOfPoints = eventsInside;
    
    if (subset)
    {
        for (NSUInteger subsetNo = 0; subsetNo < eventsInside; subsetNo++)
        {
            NSUInteger eventNo = subset[subsetNo];
            
            dotPlotData.points[subsetNo].xVal = (double)fcsFile.events[eventNo][xPar];
            dotPlotData.points[subsetNo].yVal = (double)fcsFile.events[eventNo][yPar];
        }
    }
    else
    {
        for (NSUInteger eventNo = 0; eventNo < eventsInside; eventNo++)
        {            
            dotPlotData.points[eventNo].xVal = (double)fcsFile.events[eventNo][xPar];
            dotPlotData.points[eventNo].yVal = (double)fcsFile.events[eventNo][yPar];
        }
    }

    NSLog(@"Max count:  %i", dotPlotData.countForMaxBin);
    
    return dotPlotData;
}


+ (PlotDataCalculator *)densityDataForFCSFile:(FCSFile *)fcsFile
                                       insidePlot:(Plot *)plot
                                           subset:(NSUInteger *)subset
                                      subsetCount:(NSUInteger)subsetCount
{
    NSInteger eventsInside = subsetCount;
    
    if (!subset)
    {
        eventsInside = fcsFile.noOfEvents;
    }
    
    NSInteger xPar = plot.xParNumber.integerValue - 1;
    NSInteger yPar = plot.yParNumber.integerValue - 1;
    
    double xRange = fcsFile.actualRanges[xPar].maxValue;
    double yRange = fcsFile.actualRanges[yPar].maxValue;
    
    // if log-scale create bin intervals with same relative spacing
    // assure the correct column and row is picked depending on data value
    
    
    double maxIndex = (double)(BIN_COUNT - 1);
    
    PlotPoint plotPoint;
    NSUInteger **binValues = calloc(BIN_COUNT, sizeof(NSUInteger *));
    for (NSUInteger i = 0; i < BIN_COUNT; i++)
    {
        binValues[i] = calloc(BIN_COUNT, sizeof(NSUInteger));
    }
    
    if (subset)
    {
        for (NSUInteger subsetNo = 0; subsetNo < subsetCount; subsetNo++)
        {
            NSUInteger eventNo = subset[subsetNo];
            
            plotPoint.xVal = fcsFile.events[eventNo][xPar];
            plotPoint.yVal = fcsFile.events[eventNo][yPar];
            
            NSUInteger col = (plotPoint.xVal / xRange) * maxIndex;
            NSUInteger row = (plotPoint.yVal / yRange) * maxIndex;
            
            binValues[col][row] += 1;
        }
    }
    else
    {
        for (NSUInteger eventNo = 0; eventNo < eventsInside; eventNo++)
        {
            plotPoint.xVal = fcsFile.events[eventNo][xPar];
            plotPoint.yVal = fcsFile.events[eventNo][yPar];
            
            NSUInteger col = (plotPoint.xVal / xRange) * maxIndex;
            NSUInteger row = (plotPoint.yVal / yRange) * maxIndex;
            
            binValues[col][row] += 1;
        }
    }
    
    PlotDataCalculator *densityPlotData = [PlotDataCalculator.alloc init];
    
    
    densityPlotData.points = calloc(BIN_COUNT * BIN_COUNT, sizeof(DensityPoint));
    NSUInteger recordNo = 0;
    NSInteger count = 0;
    for (NSUInteger rowNo = 0; rowNo < BIN_COUNT; rowNo++)
    {
        for (NSUInteger colNo = 0; colNo < BIN_COUNT; colNo++)
        {
            count = binValues[colNo][rowNo];
            if (count > 0)
            {
                densityPlotData.points[recordNo].count = count;
                densityPlotData.points[recordNo].xVal = (double)colNo * (xRange / maxIndex);
                densityPlotData.points[recordNo].yVal = (double)rowNo * (yRange / maxIndex);
                
                [densityPlotData _checkForMaxCount:densityPlotData.points[recordNo].count];
                
                recordNo++;
            }

        }
    }
    densityPlotData.numberOfPoints = recordNo;
    
    for (NSUInteger i = 0; i < BIN_COUNT; i++)
    {
        free(binValues[i]);
    }
    free(binValues);
    
    NSLog(@"Max count:  %i", densityPlotData.countForMaxBin);

    return densityPlotData;
}

- (void)_checkForMaxCount:(NSUInteger)count
{
    if (count > _countForMaxBin)
    {
        _countForMaxBin = count;
    }
}


+ (PlotDataCalculator *)histogramForFCSFile:(FCSFile *)fcsFile
                                 insidePlot:(Plot *)plot
                                     subset:(NSUInteger *)subset
                                subsetCount:(NSUInteger)subsetCount
{
    NSInteger eventsInside = subsetCount;
    
    if (!subset)
    {
        eventsInside = fcsFile.noOfEvents;
    }
    
    NSInteger xPar = plot.xParNumber.integerValue - 1;
    
    NSString *rangeKey = [@"$P" stringByAppendingFormat:@"%iR", plot.xParNumber.integerValue];
    Keyword *rangeKeyword = [plot.analysis.measurement keywordWithKey:rangeKey];
    double xRange = rangeKeyword.value.doubleValue;
        
    double maxIndex = (double)(HISTOGRAM_COUNT - 1);
    
    double dataPoint;
    NSUInteger *histogramValues = calloc(HISTOGRAM_COUNT, sizeof(NSUInteger));

    
    if (subset)
    {
        for (NSUInteger subSetNo = 0; subSetNo < subsetCount; subSetNo++)
        {
            NSUInteger eventNo = subset[subSetNo];
            dataPoint = (double)fcsFile.events[eventNo][xPar];
            NSUInteger col = (dataPoint / xRange) * maxIndex;
            
            histogramValues[col] += 1;
        }
    }
    else
    {
        for (NSUInteger eventNo = 0; eventNo < eventsInside; eventNo++)
        {
            dataPoint = (double)fcsFile.events[eventNo][xPar];
            NSUInteger col = (dataPoint / xRange) * maxIndex;
            
            histogramValues[col] += 1;
        }
    }
    
    PlotDataCalculator *histogramPlotData = PlotDataCalculator.alloc.init;
    histogramPlotData.numberOfPoints = HISTOGRAM_COUNT;
    
    histogramPlotData.points = calloc(HISTOGRAM_COUNT, sizeof(DensityPoint));
    
    for (NSUInteger recordNo = 0; recordNo < HISTOGRAM_COUNT; recordNo++)
    {
        histogramPlotData.points[recordNo].xVal = (double)recordNo * (xRange / maxIndex);
        histogramPlotData.points[recordNo].yVal = (double)histogramValues[recordNo];
        [histogramPlotData _checkForMaxCount:histogramValues[recordNo]];
    }
    
    free(histogramValues);
    
    return histogramPlotData;
}

- (void)cleanUpPlotData
{
    free(self.points);
}


@end
