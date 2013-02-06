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
#import "FGGate.h"
#import "FGPlot.h"
#import "FGAnalysis.h"
#import "FGMeasurement.h"
#import "FGKeyword.h"

@implementation GateCalculator

+ (GateCalculator *)eventsInsideGateWithVertices:(NSArray *)vertices
                                        gateType:(GateType)gateType
                                         fcsFile:(FCSFile *)fcsFile
                                      insidePlot:(FGPlot *)plot
                                          subSet:(NSUInteger *)subSet
                                     subSetCount:(NSUInteger)subSetCount
{
    switch (gateType) {
        case kGateTypePolygon:
        case kGateTypeRectangle:
            return [GateCalculator eventsInsidePolygonGateWithVertices:vertices fcsFile:fcsFile insidePlot:plot subSet:subSet subSetCount:subSetCount];
            break;
            
        case kGateTypeEllipse:
            return nil;
            break;
            
        case kGateTypeQuadrant:
            return nil;
            break;
            
        case kGateTypeSingleRange:
            return [GateCalculator eventsInsideSingleRangeGateWithVertices:vertices fcsFile:fcsFile insidePlot:plot subSet:subSet subSetCount:subSetCount];
            break;
            
        case kGateTypeTripleRange:
            return nil;
            break;
            
        default:
            break;
    }
    return nil;
}


+ (GateCalculator *)eventsInsidePolygonGateWithVertices:(NSArray *)vertices
                                                fcsFile:(FCSFile *)fcsFile
                                             insidePlot:(FGPlot *)plot
                                                 subSet:(NSUInteger *)subSet
                                            subSetCount:(NSUInteger)subSetCount
{
    FGGate *parentGate = (FGGate *)plot.parentNode;
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
            
            plotPoint.xVal = (double)fcsFile.events[eventNo][xPar];
            plotPoint.yVal = (double)fcsFile.events[eventNo][yPar];
            
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
            plotPoint.xVal = fcsFile.events[eventNo][xPar];
            plotPoint.yVal = fcsFile.events[eventNo][yPar];
            
            if ([self _point:plotPoint insidePolygon:vertices])
            {
                gateCalculator.eventsInside[gateCalculator.numberOfCellsInside] = eventNo;
                gateCalculator.numberOfCellsInside += 1;
            }
        }
    }
    return gateCalculator;
}


+ (GateCalculator *)eventsInsideSingleRangeGateWithVertices:(NSArray *)vertices
                                                    fcsFile:(FCSFile *)fcsFile
                                                 insidePlot:(FGPlot *)plot
                                                     subSet:(NSUInteger *)subSet
                                                subSetCount:(NSUInteger)subSetCount
{
    FGGate *parentGate = (FGGate *)plot.parentNode;
    NSInteger eventsInside = parentGate.cellCount.integerValue;
    
    if (parentGate == nil)
    {
        eventsInside = fcsFile.noOfEvents;
    }
    
    GateCalculator *gateCalculator = [GateCalculator.alloc init];
    gateCalculator.eventsInside = calloc(eventsInside, sizeof(NSUInteger *));
    gateCalculator.numberOfCellsInside = 0;
    
    NSInteger xPar = plot.xParNumber.integerValue - 1;
    double xMin = [(GraphPoint *)vertices[0] x];
    double xMax = [(GraphPoint *)vertices[1] x];
    double plotPoint;
    
    if (subSet)
    {
        for (NSUInteger subSetNo = 0; subSetNo < subSetCount; subSetNo++)
        {
            NSUInteger eventNo = subSet[subSetNo];
            
            plotPoint = (double)fcsFile.events[eventNo][xPar];
            
            if (plotPoint > xMin
                && plotPoint < xMax)
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
            plotPoint = fcsFile.events[eventNo][xPar];

            if (plotPoint > xMin
                && plotPoint < xMax)
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
    
    if (polygonVertices.count == 0)
    {
        return NO;
    }
    p1 = polygonVertices[0];
    for (i = 1; i<= polygonVertices.count; i++)
    {
        p2 = polygonVertices[i % polygonVertices.count];
        if (point.yVal > MIN(p1.y,p2.y))
        {
            if (point.yVal <= MAX(p1.y,p2.y))
            {
                if (point.xVal <= MAX(p1.x,p2.x))
                {
                    if (p1.y != p2.y)
                    {
                        xinters = (point.yVal-p1.y)*(p2.x-p1.x)/(p2.y-p1.y)+p1.x;
                        if (p1.x == p2.x || point.xVal <= xinters)
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

+ (BOOL)eventInsideGateVertices:(NSArray *)vertices
                       onEvents:(FCSFile *)fcsFile
                        eventNo:(NSUInteger)eventNo
                         xParam:(NSUInteger)xPar
                         yParam:(NSUInteger)yPar
{
    PlotPoint plotPoint;
    
    plotPoint.xVal = fcsFile.events[eventNo][xPar];
    plotPoint.yVal = fcsFile.events[eventNo][yPar];
    
    if ([self _point:plotPoint insidePolygon:vertices])
    {
        NSLog(@"Inside!");
        return YES;
    }
    
    NSLog(@"Outside!");
    return NO;
}


@end
