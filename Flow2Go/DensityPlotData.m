//
//  DensityPlotData.m
//  Flow2Go
//
//  Created by Christian Hansen on 29/08/12.
//  Copyright (c) 2012 Christian Hansen. All rights reserved.
//

#import "DensityPlotData.h"
#import "FCSFile.h"
#import "Measurement.h"
#import "Analysis.h"
#import "Plot.h"
#import "Keyword.h"

@implementation DensityPlotData

#define BIN_COUNT 128

+ (DensityPlotData *)densityForPointsygonInFcsFile:(FCSFile *)fcsFile
                                       insidePlot:(Plot *)plot
                                           subSet:(NSUInteger *)subSet
                                      subSetCount:(NSUInteger)subSetCount
{
    NSInteger eventsInside = subSetCount;
    
    if (!subSet)
    {
        eventsInside = fcsFile.noOfEvents;
    }
    
    NSInteger xPar = plot.xParNumber.integerValue - 1;
    NSInteger yPar = plot.yParNumber.integerValue - 1;
    
    NSString *rangeKey = [@"$P" stringByAppendingFormat:@"%iR", plot.xParNumber.integerValue];
    Keyword *rangeKeyword = [plot.analysis.measurement keywordWithKey:rangeKey];
    double xRange = rangeKeyword.value.doubleValue;
    rangeKey = [@"$P" stringByAppendingFormat:@"%iR", plot.yParNumber.integerValue];
    rangeKeyword = [plot.analysis.measurement keywordWithKey:rangeKey];
    double yRange = rangeKeyword.value.doubleValue;
    
    double maxIndex = (double)(BIN_COUNT - 1);
    
    PlotPoint plotPoint;
    NSUInteger **binValues = calloc(BIN_COUNT, sizeof(NSUInteger *));
    for (NSUInteger i = 0; i < BIN_COUNT; i++)
    {
        binValues[i] = calloc(BIN_COUNT, sizeof(NSUInteger));
    }
    
    if (subSet)
    {
        for (NSUInteger subSetNo = 0; subSetNo < subSetCount; subSetNo++)
        {
            NSUInteger eventNo = subSet[subSetNo];
            
            plotPoint.x = (double)fcsFile.event[eventNo][xPar];
            plotPoint.y = (double)fcsFile.event[eventNo][yPar];
            
            NSUInteger row = (plotPoint.x / xRange) * maxIndex;
            NSUInteger col = (plotPoint.y / yRange) * maxIndex;
            
            binValues[col][row] += 1;
        }
    }
    else
    {
        for (NSUInteger eventNo = 0; eventNo < eventsInside; eventNo++)
        {
            plotPoint.x = fcsFile.event[eventNo][xPar];
            plotPoint.y = fcsFile.event[eventNo][yPar];
            
            NSUInteger row = (plotPoint.x / xRange) * maxIndex;
            NSUInteger col = (plotPoint.y / yRange) * maxIndex;
            
            binValues[col][row] += 1;
        }
    }
    
    DensityPlotData *densityPlotData = [DensityPlotData.alloc init];
    densityPlotData.numberOfPoints = BIN_COUNT * BIN_COUNT;
    
    densityPlotData.points = calloc(BIN_COUNT * BIN_COUNT, sizeof(DensityPoint));
    NSUInteger recordNo = 0;
    NSInteger count = 0;
    for (NSUInteger rowNo = 0; rowNo < BIN_COUNT; rowNo++)
    {
        for (NSUInteger colNo = 0; colNo < BIN_COUNT; colNo++)
        {
            densityPlotData.points[recordNo].xVal = (double)colNo * (xRange / maxIndex);
            densityPlotData.points[recordNo].yVal = (double)rowNo * (yRange / maxIndex);
            count = binValues[colNo][rowNo];
            densityPlotData.points[recordNo].count = count;
            [densityPlotData _checkForMaxCount:densityPlotData.points[recordNo].count];
            
            recordNo++;
        }
    }
    
//    recordNo = 0;
//    for (NSUInteger rowNo = 0; rowNo < 50; rowNo++)
//    {
//        for (NSUInteger colNo = 0; colNo < 50; colNo++)
//        {
//            NSLog(@"   %i %i", binValues[colNo][rowNo], densityPlotData.points[recordNo].count);
//            
//            
//            recordNo++;
//        }
//    }
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
@end
