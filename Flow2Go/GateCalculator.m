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

@implementation GateCalculator

+ (GateCalculator *)gateWithPath:(CGPathRef)path
                inView:(UIView *)aView
              onEvents:(FCSFile *)fcsFile
                xParam:(NSUInteger)xPar
                yParam:(NSUInteger)yPar
           inPlotSpace:(CPTXYPlotSpace *)aPlotSpace
{
    GateCalculator *gate = [GateCalculator.alloc init];
    gate.eventsInside = calloc(fcsFile.noOfEvents, sizeof(NSUInteger *));    
    
    double plotPoint[2];
    CGFloat yOffset = aView.frame.size.height;
    for (NSUInteger eventNo = 0; eventNo < fcsFile.noOfEvents; eventNo++)
    {
        plotPoint[0] = fcsFile.event[eventNo][xPar];
        plotPoint[1] = fcsFile.event[eventNo][yPar];
        
        CGPoint pointForEvent = [aPlotSpace plotAreaViewPointForDoublePrecisionPlotPoint:plotPoint];
        pointForEvent.y = yOffset - pointForEvent.y;
        
        if (CGPathContainsPoint(path, NULL, pointForEvent, TRUE))
        {
            gate.eventsInside[gate.numberOfCellsInside] = eventNo;
            gate.numberOfCellsInside += 1;
        }
    }
    return gate;
}

+ (GateCalculator *)gateWithVertices:(NSArray *)vertices
                            onEvents:(FCSFile *)fcsFile
                              xParam:(NSUInteger)xPar
                              yParam:(NSUInteger)yPar
{
    GateCalculator *gate = [GateCalculator.alloc init];
    gate.eventsInside = calloc(fcsFile.noOfEvents, sizeof(NSUInteger *));

    PlotPoint plotPoint;
    
    for (NSUInteger eventNo = 0; eventNo < fcsFile.noOfEvents; eventNo++)
    {
        plotPoint.x = fcsFile.event[eventNo][xPar];
        plotPoint.y = fcsFile.event[eventNo][yPar];
        
        if ([self _point:plotPoint insidePolygon:vertices])
        {
            gate.eventsInside[gate.numberOfCellsInside] = eventNo;
            gate.numberOfCellsInside += 1;
        }
    }
    return gate;
}

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

+ (GateCalculator *)eventsIn:(FCSFile *)fcsFile insideGate:(Gate *)gate
{
    GateCalculator *gateCalculator = [GateCalculator.alloc init];
    gateCalculator.eventsInside = calloc(fcsFile.noOfEvents, sizeof(NSUInteger *));
    
    
    
    NSUInteger xPar = [FCSFile parameterNumberForName:gate.xParName inFCSFile:fcsFile];
    NSUInteger yPar = [FCSFile parameterNumberForName:gate.yParName inFCSFile:fcsFile];
    
    NSLog(@"xAxisName: %@, parNo: %i", gate.xParName, xPar);
    NSLog(@"yAxisName: %@, parNo: %i", gate.yParName, yPar);
    
//    PlotPoint plotPoint;
//    
//    for (NSUInteger eventNo = 0; eventNo < fcsFile.noOfEvents; eventNo++)
//    {
//        plotPoint.x = fcsFile.event[eventNo][xPar];
//        plotPoint.y = fcsFile.event[eventNo][yPar];
//        
//        if ([self _point:plotPoint insidePolygon:vertices])
//        {
//            gate.eventsInside[gate.numberOfCellsInside] = eventNo;
//            gate.numberOfCellsInside += 1;
//        }
//    }
    return gateCalculator;
}


+ (BOOL)_eventInsideBoundingBox:(BoundingBox)bounds forPar1:(double)par1 andPar2:(double)par2
{
    if (bounds.lower.x <= par1
        && bounds.upper.x >= par1)
    {
        if (bounds.lower.y <= par2
            && bounds.upper.y >= par2)
        {
            return YES;
        }
    }
    return NO;
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
