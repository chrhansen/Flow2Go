//
//  DensityPlotData.m
//  Flow2Go
//
//  Created by Christian Hansen on 29/08/12.
//  Copyright (c) 2012 Christian Hansen. All rights reserved.
//

#import "FGPlotDataCalculator.h"
#import "FGFCSFile.h"
#import "FGMeasurement.h"
#import "FGAnalysis.h"
#import "FGPlot+Management.h"
#import "FGKeyword.h"

@implementation FGPlotDataCalculator

#define BIN_COUNT 512
#define HISTOGRAM_AVERAGING 9

+ (FGPlotDataCalculator *)plotDataForFCSFile:(FGFCSFile *)fcsFile
                                  insidePlot:(FGPlot *)plot
                                      subset:(NSUInteger *)subset
                                 subsetCount:(NSUInteger)subsetCount
{
    if (!fcsFile || !plot) {
        NSLog(@"Error: fcsFile or plot is nil: %s", __PRETTY_FUNCTION__);
        return nil;
    }
    return [self plotDataForFCSFile:fcsFile plotOptions:plot.plotOptions subset:subset subsetCount:subsetCount];
}

+ (FGPlotDataCalculator *)plotDataForFCSFile:(FGFCSFile *)fcsFile
                                 plotOptions:(NSDictionary *)plotOptions
                                      subset:(NSUInteger *)subset
                                 subsetCount:(NSUInteger)subsetCount
{
    if (!fcsFile || !plotOptions) {
        NSLog(@"Error: fcsFile or plotoptions is nil: %s", __PRETTY_FUNCTION__);
        return nil;
    }
    FGPlotType plotType = [plotOptions[PlotType] integerValue];
    switch (plotType)
    {
        case kPlotTypeDot:
            return [FGPlotDataCalculator dotDataForFCSFile:fcsFile plotOptions:plotOptions subset:subset subsetCount:subsetCount];
            break;
            
        case kPlotTypeDensity:
            return [FGPlotDataCalculator densityDataForFCSFile:fcsFile plotOptions:plotOptions subset:subset subsetCount:subsetCount];
            break;
            
        case kPlotTypeHistogram:
            return [FGPlotDataCalculator histogramForFCSFile:fcsFile plotOptions:plotOptions subset:subset subsetCount:subsetCount];
            break;
            
        default:
            NSLog(@"Error: unknown plottype: %d, %s", plotType, __PRETTY_FUNCTION__);
            break;
    }
    return nil;
}


+ (FGPlotDataCalculator *)dotDataForFCSFile:(FGFCSFile *)fcsFile
                                plotOptions:(NSDictionary *)plotOptions
                                     subset:(NSUInteger *)subset
                                subsetCount:(NSUInteger)subsetCount
{
    FGPlotDataCalculator *dotPlotData = [FGPlotDataCalculator.alloc init];
    NSInteger eventsInside = fcsFile.noOfEvents;
    
    if (subset)
    {
        eventsInside = subsetCount;
    }
    
    NSInteger xPar = [plotOptions[XParNumber] integerValue] - 1;
    NSInteger yPar = [plotOptions[YParNumber] integerValue] - 1;
    
    dotPlotData.points = calloc(eventsInside, sizeof(FGDensityPoint));
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


+ (FGPlotDataCalculator *)densityDataForFCSFile:(FGFCSFile *)fcsFile
                                    plotOptions:(NSDictionary *)plotOptions
                                         subset:(NSUInteger *)subset
                                    subsetCount:(NSUInteger)subsetCount
{
    if (!fcsFile || !plotOptions) {
        NSLog(@"Error: fcsFile or Plotoptions is nil: %s", __PRETTY_FUNCTION__);
        return nil;
    }
    
    NSInteger eventsInside = subsetCount;
    
    if (!subset)
    {
        eventsInside = fcsFile.noOfEvents;
    }
    
    NSInteger xPar = [plotOptions[XParNumber] integerValue] - 1;
    NSInteger yPar = [plotOptions[YParNumber] integerValue] - 1;
    
    FGAxisType xAxisType = [plotOptions[XAxisType] integerValue];
    FGAxisType yAxisType = [plotOptions[YAxisType] integerValue];
    
    double xMin = fcsFile.ranges[xPar].minValue;
    double xMax = fcsFile.ranges[xPar].maxValue;
    double yMin = fcsFile.ranges[yPar].minValue;
    double yMax = fcsFile.ranges[yPar].maxValue;
    
    double xFactor = pow(xMin/xMax, 1.0/(BIN_COUNT - 1.0));
    double yFactor = pow(yMin/yMax, 1.0/(BIN_COUNT - 1.0));
    
    double log10XFactor = log10(xFactor);
    double log10YFactor = log10(yFactor);
    
    double log10XMin = log10(xMin);
    double log10YMin = log10(yMin);
    
    double maxIndex = (double)(BIN_COUNT - 1);
    
    FGPlotPoint plotPoint;
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
                    col = (log10XMin - log10(plotPoint.xVal))/log10XFactor;
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
                    row = (log10YMin - log10(plotPoint.yVal))/log10YFactor;
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
                    col = (log10XMin - log10(plotPoint.xVal))/log10XFactor;
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
                    row = (log10YMin - log10(plotPoint.yVal))/log10YFactor;
                    break;
                    
                default:
                    break;
            }
            binValues[col][row] += 1;
        }
    }
    
    FGPlotDataCalculator *densityPlotData = [FGPlotDataCalculator.alloc init];
    
    
    densityPlotData.points = calloc(BIN_COUNT * BIN_COUNT, sizeof(FGDensityPoint));
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
                        densityPlotData.points[recordNo].xVal = pow(10, log10XMin - log10XFactor * (double)colNo);
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
                        densityPlotData.points[recordNo].yVal = pow(10, log10YMin - log10YFactor * (double)rowNo);
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
    
    return densityPlotData;
}



- (void)_checkForMaxCount:(NSUInteger)count
{
    if (count > _countForMaxBin)
    {
        _countForMaxBin = count;
    }
}


+ (FGPlotDataCalculator *)histogramForFCSFile:(FGFCSFile *)fcsFile
                                  plotOptions:(NSDictionary *)plotOptions
                                       subset:(NSUInteger *)subset
                                  subsetCount:(NSUInteger)subsetCount
{
    if (!fcsFile || !plotOptions) {
        NSLog(@"Error: fcsFile or Plotoptions is nil: %s", __PRETTY_FUNCTION__);
        return nil;
    }
    
    NSInteger eventsInside = subsetCount;
    
    if (!subset)
    {
        eventsInside = fcsFile.noOfEvents;
    }
    
    NSInteger parIndex = [plotOptions[XParNumber] integerValue] - 1;
    
    FGAxisType axisType = [plotOptions[XAxisType] integerValue];
    double minValue = fcsFile.ranges[parIndex].minValue;
    double maxValue = fcsFile.ranges[parIndex].maxValue;
    NSUInteger colCount = (NSUInteger)(maxValue + 1.0);
    
    double factor = pow(minValue/maxValue, 1.0/(maxValue + 1.0));
    double log10Factor = log10(factor);
    double log10MinValue = log10(minValue);
    
    NSUInteger col = 0;
    
    double dataPoint;
    NSUInteger *histogramValues = calloc(colCount, sizeof(NSUInteger));
    
    if (subset)
    {
        for (NSUInteger subSetNo = 0; subSetNo < subsetCount; subSetNo++)
        {
            NSUInteger eventNo = subset[subSetNo];
            dataPoint = fcsFile.events[eventNo][parIndex];
            
            switch (axisType)
            {
                case kAxisTypeLinear:
                    col = dataPoint;
                    break;
                    
                case kAxisTypeLogarithmic:
                    col = (log10MinValue - log10(dataPoint))/log10Factor;
                    break;
                    
                default:
                    break;
            }
            histogramValues[col] += 1;
        }
    }
    else
    {
        for (NSUInteger eventNo = 0; eventNo < eventsInside; eventNo++)
        {
            dataPoint = fcsFile.events[eventNo][parIndex];
            
            switch (axisType)
            {
                case kAxisTypeLinear:
                    col = dataPoint;
                    break;
                    
                case kAxisTypeLogarithmic:
                    col = (log10MinValue - log10(dataPoint))/log10Factor;
                    break;
                    
                default:
                    break;
            }
            
            histogramValues[col] += 1;
        }
    }
    
    FGPlotDataCalculator *histogramPlotData = FGPlotDataCalculator.alloc.init;
    histogramPlotData.numberOfPoints = colCount;
    histogramPlotData.points = calloc(colCount, sizeof(FGDensityPoint));
    
    for (NSUInteger colNo = 0; colNo < colCount; colNo++)
    {
        switch (axisType)
        {
            case kAxisTypeLinear:
                histogramPlotData.points[colNo].xVal = (double)colNo;
                break;
                
            case kAxisTypeLogarithmic:
                histogramPlotData.points[colNo].xVal = pow(10, log10MinValue - log10Factor*(double)colNo);
                break;
                
            default:
                break;
        }
    }
    
    double runningAverage = 0.0;
    double divideBy = 1.0 + 2 * HISTOGRAM_AVERAGING;
    
    for (NSUInteger i = 0; i < colCount; i++)
    {
        if (i >= HISTOGRAM_AVERAGING
            && i < colCount - HISTOGRAM_AVERAGING)
        {
            for (NSUInteger j = i - HISTOGRAM_AVERAGING; j < i + HISTOGRAM_AVERAGING; j++)
            {
                runningAverage += (double)histogramValues[j];
            }
            
            histogramPlotData.points[i].yVal = runningAverage / divideBy;
        }
        //        else if (i < HISTOGRAM_AVERAGING)
        //        {
        //            for (NSUInteger j = 0; j <= i; j++)
        //            {
        //                runningAverage += (double)histogramValues[j];
        //            }
        //
        //            histogramPlotData.points[i].yVal = runningAverage / (double)(i+1);
        //        }
        //        else if (i >= maxIndex - HISTOGRAM_AVERAGING)
        //        {
        //            NSUInteger loops = 0;
        //            for (NSUInteger j = i; j < maxIndex + 1; j++)
        //            {
        //                runningAverage += (double)histogramValues[j];
        //                loops += 1;
        //            }
        //
        //            histogramPlotData.points[i].yVal = runningAverage / (double)loops;
        //        }
        [histogramPlotData _checkForMaxCount:(NSUInteger)histogramPlotData.points[i].yVal];
        runningAverage = 0.0;
    }
    free(histogramValues);
    
    return histogramPlotData;
}


- (void)cleanUpPlotData
{
    free(self.points);
}


@end
