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
