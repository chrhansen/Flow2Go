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
#define HISTOGRAM_AVERAGING 20

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
    
    NSLog(@"start calculating density");
    
    if (!subset)
    {
        eventsInside = fcsFile.noOfEvents;
    }
    
    NSInteger xPar = plot.xParNumber.integerValue - 1;
    NSInteger yPar = plot.yParNumber.integerValue - 1;
    
    AxisType xAxisType = plot.xAxisType.integerValue;
    AxisType yAxisType = plot.yAxisType.integerValue;
    
    double xMin = fcsFile.ranges[xPar].minValue;
    double xMax = fcsFile.ranges[xPar].maxValue;

    double yMin = fcsFile.ranges[yPar].minValue;
    double yMax = fcsFile.ranges[yPar].maxValue;
    
    double xFactor = pow(xMin/xMax, 1.0/BIN_COUNT);
    double yFactor = pow(yMin/yMax, 1.0/BIN_COUNT);
    
    double log10XFactor = log10(xFactor);
    double log10YFactor = log10(yFactor);
    
    double log10XMin = log10(xMin);
    double log10YMin = log10(yMin);

    
    
    double maxIndex = (double)(BIN_COUNT - 1);
    
    PlotPoint plotPoint;
    NSUInteger col = 0;
    NSUInteger row = 0;
    
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
            
            switch (xAxisType)
            {
                case kAxisTypeLinear:
                    col = (plotPoint.xVal / xMax) * maxIndex;
                    break;
                    
                case kAxisTypeLogarithmic:
                    col = (log10(xMin) - log10(plotPoint.xVal))/log10(xFactor);
                    break;
                    
                default:
                    break;
            }
            
            switch (yAxisType)
            {
                case kAxisTypeLinear:
                    row = (plotPoint.yVal / yMax) * maxIndex;
                    break;
                    
                case kAxisTypeLogarithmic:
                    row = (log10(yMin) - log10(plotPoint.yVal))/log10(yFactor);
                    break;
                    
                default:
                    break;
            }
            
            
            binValues[col][row] += 1;
        }
    }
    else
    {
        for (NSUInteger eventNo = 0; eventNo < eventsInside; eventNo++)
        {
            plotPoint.xVal = fcsFile.events[eventNo][xPar];
            plotPoint.yVal = fcsFile.events[eventNo][yPar];
            
            switch (xAxisType)
            {
                case kAxisTypeLinear:
                    col = (plotPoint.xVal / xMax) * maxIndex;
                    break;
                    
                case kAxisTypeLogarithmic:
                    col = (log10(xMin) - log10(plotPoint.xVal))/log10(xFactor);
                    break;
                    
                default:
                    break;
            }
            
            switch (yAxisType)
            {
                case kAxisTypeLinear:
                    row = (plotPoint.yVal / yMax) * maxIndex;
                    break;
                    
                case kAxisTypeLogarithmic:
                    row = (log10(yMin) - log10(plotPoint.yVal))/log10(yFactor);
                    break;
                    
                default:
                    break;
            }
            
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
                [densityPlotData _checkForMaxCount:densityPlotData.points[recordNo].count];
                
                switch (xAxisType)
                {
                    case kAxisTypeLinear:
                        densityPlotData.points[recordNo].xVal = (double)colNo * (xMax / maxIndex);
                        break;
                        
                    case kAxisTypeLogarithmic:
                        densityPlotData.points[recordNo].xVal = pow(10, log10(xMin) - log10(xFactor)*(double)colNo);
                        break;
                        
                    default:
                        break;
                }
                switch (yAxisType)
                {
                    case kAxisTypeLinear:
                        densityPlotData.points[recordNo].yVal = (double)rowNo * (yMax / maxIndex);
                        break;
                        
                    case kAxisTypeLogarithmic:
                        densityPlotData.points[recordNo].yVal = pow(10, log10(yMin) - log10(yFactor)*(double)rowNo);
                        break;
                        
                    default:
                        break;
                }
                
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
    NSLog(@"finished calculating density");

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
        
    NSUInteger maxIndex = (NSUInteger)(xRange - 1.0);
    
    double dataPoint;
    NSUInteger *histogramValues = calloc((NSUInteger)xRange, sizeof(NSUInteger));
    
    if (subset)
    {
        for (NSUInteger subSetNo = 0; subSetNo < subsetCount; subSetNo++)
        {
            NSUInteger eventNo = subset[subSetNo];
            dataPoint = fcsFile.events[eventNo][xPar];
            NSUInteger col = dataPoint;
            
            histogramValues[col] += 1;
        }
    }
    else
    {
        for (NSUInteger eventNo = 0; eventNo < eventsInside; eventNo++)
        {
            dataPoint = fcsFile.events[eventNo][xPar];
            NSUInteger col = dataPoint;
            
            histogramValues[col] += 1;
        }
    }
    
    PlotDataCalculator *histogramPlotData = PlotDataCalculator.alloc.init;
    histogramPlotData.numberOfPoints = maxIndex + 1;
    histogramPlotData.points = calloc(maxIndex + 1, sizeof(DensityPoint));
    
    double runningSum = 0.0;
    
    for (NSUInteger recordNo = 0; recordNo < maxIndex + 1; recordNo++)
    {
        if (recordNo >= HISTOGRAM_AVERAGING)
        {
            runningSum -= (double)histogramValues[recordNo - HISTOGRAM_AVERAGING];
        }
        runningSum += (double)histogramValues[recordNo];
        histogramPlotData.points[recordNo].xVal = (double)recordNo;
        histogramPlotData.points[recordNo].yVal = runningSum / HISTOGRAM_AVERAGING;
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
