//
//  Gate.m
//  Flow2Go
//
//  Created by Christian Hansen on 14/08/12.
//  Copyright (c) 2012 Christian Hansen. All rights reserved.
//

#import "FGGateCalculator.h"
#import "FGFCSFile.h"
#import "FGPlot+Management.h"
#import "FGGate+Management.h"

@implementation FGGateCalculator

- (void)dealloc
{
    if (_eventsInside) free(_eventsInside);
}


+ (FGGateCalculator *)eventsInsideGatesWithDatas:(NSArray *)gateDatas fcsFile:(FGFCSFile *)fcsFile
{
    if (gateDatas == nil || gateDatas.count == 0) {
        // No gates return all events
        return nil;
    }
    FGGateCalculator *gateCalculator;
    for (NSDictionary *gateData in gateDatas) {
        gateCalculator = [self eventsInsideGateWithData:gateData fcsFile:fcsFile subSet:gateCalculator.eventsInside subSetCount:gateCalculator.countOfEventsInside];
    }
    return gateCalculator;
}


+ (FGGateCalculator *)eventsInsideGateWithData:(NSDictionary *)gateData fcsFile:(FGFCSFile *)fcsFile subSet:(NSUInteger *)subSet subSetCount:(NSUInteger)subSetCount
{
    FGGateType gateType = [gateData[GateType] integerValue];
    switch (gateType) {
        case kGateTypePolygon:
        case kGateTypeRectangle:
            return [FGGateCalculator eventsInsidePolygonGateWithXParameter:gateData[XParName] yParameter:gateData[YParName] vertices:gateData[Vertices] fcsFile:fcsFile subSet:subSet subSetCount:subSetCount];
            break;
            
        case kGateTypeEllipse:
            return nil;
            break;
            
        case kGateTypeQuadrant:
            return nil;
            break;
            
        case kGateTypeSingleRange:
            return [FGGateCalculator eventsInsideSingleRangeGateWithXParameter:gateData[XParName] vertices:gateData[Vertices] fcsFile:fcsFile subSet:subSet subSetCount:subSetCount];
            break;
            
        case kGateTypeTripleRange:
            return nil;
            break;
            
        default:
            break;
    }
    return nil;
}


+ (FGGateCalculator *)eventsInsidePolygonGateWithXParameter:(NSString *)xParShortName
                                                 yParameter:(NSString *)yParShortName
                                                   vertices:(NSArray *)vertices
                                                    fcsFile:(FGFCSFile *)fcsFile
                                                     subSet:(NSUInteger *)subSet
                                                subSetCount:(NSUInteger)subSetCount
{
    NSInteger eventsInside = subSetCount;
    if (!subSet)
    {
        eventsInside = fcsFile.noOfEvents;
    }
    
    FGGateCalculator *gateCalculator = [FGGateCalculator.alloc init];
    gateCalculator.eventsInside = calloc(eventsInside, sizeof(NSUInteger *));
    gateCalculator.countOfEventsInside = 0;
    
    NSInteger xPar = [FGFCSFile parameterNumberForShortName:xParShortName inFCSFile:fcsFile] - 1;
    NSInteger yPar = [FGFCSFile parameterNumberForShortName:yParShortName inFCSFile:fcsFile] - 1;
    
    FGPlotPoint plotPoint;
    NSUInteger eventNo;
    
    if (subSet)
    {
        for (NSUInteger subSetNo = 0; subSetNo < subSetCount; subSetNo++)
        {
            eventNo = subSet[subSetNo];
            
            plotPoint.xVal = (double)fcsFile.events[eventNo][xPar];
            plotPoint.yVal = (double)fcsFile.events[eventNo][yPar];
            
            if ([self _point:plotPoint insidePolygon:vertices])
            {
                gateCalculator.eventsInside[gateCalculator.countOfEventsInside] = eventNo;
                gateCalculator.countOfEventsInside += 1;
            }
        }
    }
    else
    {
        for (eventNo = 0; eventNo < eventsInside; eventNo++)
        {
            plotPoint.xVal = fcsFile.events[eventNo][xPar];
            plotPoint.yVal = fcsFile.events[eventNo][yPar];
            
            if ([self _point:plotPoint insidePolygon:vertices])
            {
                gateCalculator.eventsInside[gateCalculator.countOfEventsInside] = eventNo;
                gateCalculator.countOfEventsInside += 1;
            }
        }
    }
    return gateCalculator;
}


+ (FGGateCalculator *)eventsInsideSingleRangeGateWithXParameter:(NSString *)xParShortName
                                                       vertices:(NSArray *)vertices
                                                        fcsFile:(FGFCSFile *)fcsFile
                                                         subSet:(NSUInteger *)subSet
                                                    subSetCount:(NSUInteger)subSetCount
{
    NSInteger eventsInside = subSetCount;
    if (!subSet)
    {
        eventsInside = fcsFile.noOfEvents;
    }
    
    FGGateCalculator *gateCalculator = [FGGateCalculator.alloc init];
    gateCalculator.eventsInside = calloc(eventsInside, sizeof(NSUInteger *));
    gateCalculator.countOfEventsInside = 0;
    
    NSInteger xPar = [FGFCSFile parameterNumberForShortName:xParShortName inFCSFile:fcsFile] - 1;
    double xMin = [(FGGraphPoint *)vertices[0] x];
    double xMax = [(FGGraphPoint *)vertices[1] x];
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
                gateCalculator.eventsInside[gateCalculator.countOfEventsInside] = eventNo;
                gateCalculator.countOfEventsInside += 1;
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
                gateCalculator.eventsInside[gateCalculator.countOfEventsInside] = eventNo;
                gateCalculator.countOfEventsInside += 1;
            }
        }
    }
    return gateCalculator;
}


+ (FGGateCalculator *)eventsInsideEllipseGateWithXParameter:(NSString *)xParShortName
                                                 yParameter:(NSString *)yParShortName
                                                   vertices:(NSArray *)vertices
                                                    fcsFile:(FGFCSFile *)fcsFile
                                                     subSet:(NSUInteger *)subSet
                                                subSetCount:(NSUInteger)subSetCount
{
    NSInteger eventsInside = subSetCount;
    if (!subSet)
    {
        eventsInside = fcsFile.noOfEvents;
    }
    
    FGGateCalculator *gateCalculator = [FGGateCalculator.alloc init];
    gateCalculator.eventsInside = calloc(eventsInside, sizeof(NSUInteger *));
    gateCalculator.countOfEventsInside = 0;
    
    NSInteger xPar = [FGFCSFile parameterNumberForShortName:xParShortName inFCSFile:fcsFile] - 1;
    NSInteger yPar = [FGFCSFile parameterNumberForShortName:yParShortName inFCSFile:fcsFile] - 1;
    FGPlotPoint ellipsePoint1, ellipsePoint2, testPoint;
    ellipsePoint1.xVal = [(FGGraphPoint *)vertices[0] x];
    ellipsePoint1.yVal = [(FGGraphPoint *)vertices[0] y];
    ellipsePoint2.xVal = [(FGGraphPoint *)vertices[1] x];
    ellipsePoint2.yVal = [(FGGraphPoint *)vertices[1] y];
    double plotPoint;
    NSUInteger eventNo;
    
    if (subSet)
    {
        for (NSUInteger subSetNo = 0; subSetNo < subSetCount; subSetNo++)
        {
            eventNo = subSet[subSetNo];
            
            testPoint.xVal = (double)fcsFile.events[eventNo][xPar];
            testPoint.yVal = (double)fcsFile.events[eventNo][yPar];
            
            if ([self _point:testPoint insideEllipseWithPoint1:ellipsePoint1 andPoint2:ellipsePoint2])
            {
                gateCalculator.eventsInside[gateCalculator.countOfEventsInside] = eventNo;
                gateCalculator.countOfEventsInside += 1;
            }
        }
    }
    else
    {
        for (eventNo = 0; eventNo < eventsInside; eventNo++)
        {
            testPoint.xVal = (double)fcsFile.events[eventNo][xPar];
            testPoint.yVal = (double)fcsFile.events[eventNo][yPar];
            
            if ([self _point:testPoint insideEllipseWithPoint1:ellipsePoint1 andPoint2:ellipsePoint2])
            {
                gateCalculator.eventsInside[gateCalculator.countOfEventsInside] = eventNo;
                gateCalculator.countOfEventsInside += 1;
            }
        }
    }
    return gateCalculator;
}


+ (BOOL)_point:(FGPlotPoint)testPoint insideEllipseWithPoint1:(FGPlotPoint)point1 andPoint2:(FGPlotPoint)point2
{
    // implement inside-ellipse-checking-code
    
    return NO;
}


+ (BOOL)_point:(FGPlotPoint)point insidePolygon:(NSArray *)polygonVertices
{
    int counter = 0;
    int i;
    double xinters;
    FGGraphPoint *p1, *p2;
    
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

@end
