//
//  Gate.m
//  Flow2Go
//
//  Created by Christian Hansen on 14/08/12.
//  Copyright (c) 2012 Christian Hansen. All rights reserved.
//

#import "GateCalculator.h"
#import "FCSFile.h"
#import "CorePlot-CocoaTouch.h"
#import "GraphPoint.h"
#import "Gate.h"
#import "Plot.h"
#import "Analysis.h"
#import "Measurement.h"
#import "Keyword.h"

@implementation GateCalculator


+ (BOOL)eventInsideGateVertices:(NSArray *)vertices
                       onEvents:(FCSFile *)fcsFile
                        eventNo:(NSUInteger)eventNo
                         xParam:(NSUInteger)xPar
                         yParam:(NSUInteger)yPar
{
    PlotPoint plotPoint;
    
    plotPoint.x = fcsFile.event[eventNo][xPar];
    plotPoint.y = fcsFile.event[eventNo][yPar];
    
    if ([self _point:plotPoint insidePolygon:vertices])
    {
        NSLog(@"Inside!");
        return YES;
    }
    
    NSLog(@"Outside!");
    return NO;
}

+ (GateCalculator *)eventsInsidePolygon:(NSArray *)vertices
                                fcsFile:(FCSFile *)fcsFile
                             insidePlot:(Plot *)plot
                                 subSet:(NSUInteger *)subSet
                            subSetCount:(NSUInteger)subSetCount
{
    Gate *parentGate = (Gate *)plot.parentNode;
    NSInteger eventsInside = parentGate.cellCount.integerValue;

    if (parentGate == nil)
    {
        eventsInside = fcsFile.noOfEvents;
    }
    
    GateCalculator *gateCalculator = [GateCalculator.alloc init];
    gateCalculator.eventsInside = calloc(eventsInside, sizeof(NSUInteger *));
    gateCalculator.numberOfCellsInside = 0;
    
    NSInteger xPar = plot.xParNumber.integerValue - 1;
    NSInteger yPar = plot.yParNumber.integerValue - 1;
        
    PlotPoint plotPoint;
    
    if (subSet)
    {
        for (NSUInteger subSetNo = 0; subSetNo < subSetCount; subSetNo++)
        {
            NSUInteger eventNo = subSet[subSetNo];
            
            plotPoint.x = (double)fcsFile.event[eventNo][xPar];
            plotPoint.y = (double)fcsFile.event[eventNo][yPar];
            
            if ([self _point:plotPoint insidePolygon:vertices])
            {
                gateCalculator.eventsInside[gateCalculator.numberOfCellsInside] = eventNo;
                gateCalculator.numberOfCellsInside += 1;
            }
        }
    }
    else
    {
        for (NSUInteger eventNo = 0; eventNo < eventsInside; eventNo++)
        {
            plotPoint.x = fcsFile.event[eventNo][xPar];
            plotPoint.y = fcsFile.event[eventNo][yPar];
            
            if ([self _point:plotPoint insidePolygon:vertices])
            {
                gateCalculator.eventsInside[gateCalculator.numberOfCellsInside] = eventNo;
                gateCalculator.numberOfCellsInside += 1;
            }
        }
    }
    return gateCalculator;
}


#define BIN_COUNT 256

+ (GateCalculator *)densityForPointsygonInFcsFile:(FCSFile *)fcsFile
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
    
    GateCalculator *gateCalculator = [GateCalculator.alloc init];
    gateCalculator.numberOfDensityPoints = BIN_COUNT * BIN_COUNT;
    
    gateCalculator.densityPoints = calloc(BIN_COUNT * BIN_COUNT, sizeof(DensityPoint));
    NSUInteger recordNo = 0;
    
    for (NSUInteger rowNo = 0; rowNo < BIN_COUNT; rowNo++)
    {
        for (NSUInteger colNo = 0; colNo < BIN_COUNT; colNo++)
        {
            gateCalculator.densityPoints[recordNo].xVal = (double)colNo * xRange / maxIndex;
            gateCalculator.densityPoints[recordNo].yVal = (double)rowNo * yRange / maxIndex;
            gateCalculator.densityPoints[recordNo].count = binValues[colNo][rowNo];
            
            recordNo++;
        }
    }
    
    return gateCalculator;
}

- (NSUInteger)binNumberForPlotPoint:(PlotPoint)point
{
    // Create logic that determines which bin a point belongs to
    return 0;
}


+ (BOOL)_point:(PlotPoint)point insidePolygon:(NSArray *)polygonVertices
{
    int counter = 0;
    int i;
    double xinters;
    GraphPoint *p1, *p2;
    
    p1 = polygonVertices[0];
    for (i = 1; i<= polygonVertices.count; i++)
    {
        p2 = polygonVertices[i % polygonVertices.count];
        if (point.y > MIN(p1.y,p2.y))
        {
            if (point.y <= MAX(p1.y,p2.y))
            {
                if (point.x <= MAX(p1.x,p2.x))
                {
                    if (p1.y != p2.y)
                    {
                        xinters = (point.y-p1.y)*(p2.x-p1.x)/(p2.y-p1.y)+p1.x;
                        if (p1.x == p2.x || point.x <= xinters)
                        {
                            counter++;
                        }
                    }
                }
            }
        }
        p1 = p2;
    }
    
    if (counter % 2 == 0)
        return NO;
    else
        return YES;
}




@end
