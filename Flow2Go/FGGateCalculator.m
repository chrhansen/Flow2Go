//
//  Gate.m
//  Flow2Go
//
//  Created by Christian Hansen on 14/08/12.
//  Copyright (c) 2012 Christian Hansen. All rights reserved.
//

#import "FGGateCalculator.h"
#import "FGFCSFile.h"
#import "FGGraphPoint.h"
#import "FGPlot+Management.h"

@implementation FGGateCalculator

- (void)dealloc
{
    free(_eventsInside);
}


+ (FGGateCalculator *)eventsInsideGateWithXParameter:(NSString *)xParShortName
                                          yParameter:(NSString *)yParShortName
                                            gateType:(FGGateType)gateType
                                            vertices:(NSArray *)vertices
                                             fcsFile:(FGFCSFile *)fcsFile
                                              subSet:(NSUInteger *)subSet
                                         subSetCount:(NSUInteger)subSetCount
{
    switch (gateType) {
        case kGateTypePolygon:
        case kGateTypeRectangle:
            return [FGGateCalculator eventsInsidePolygonGateWithXParameter:xParShortName yParameter:yParShortName gateType:gateType vertices:vertices fcsFile:fcsFile subSet:subSet subSetCount:subSetCount];
            break;
            
        case kGateTypeEllipse:
            return nil;
            break;
            
        case kGateTypeQuadrant:
            return nil;
            break;
            
        case kGateTypeSingleRange:
            return [FGGateCalculator eventsInsideSingleRangeGateWithXParameter:xParShortName gateType:gateType vertices:vertices fcsFile:fcsFile subSet:subSet subSetCount:subSetCount];
            break;
            
        case kGateTypeTripleRange:
            return nil;
            break;
            
        default:
            break;
    }
    return nil;
}


+ (void)eventsInsideGateWithXParameter:(NSString *)xParShortName
                            yParameter:(NSString *)yParShortName
                              gateType:(FGGateType)gateType
                              vertices:(NSArray *)vertices
                               fcsFile:(FGFCSFile *)fcsFile
                                subSet:(NSUInteger *)subSet
                           subSetCount:(NSUInteger)subSetCount
                          completion:(void (^)(NSData *subset, NSUInteger numberOfCellsInside))completion
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        FGGateCalculator *gateCalculator = [self eventsInsideGateWithXParameter:xParShortName yParameter:yParShortName gateType:gateType vertices:vertices fcsFile:fcsFile subSet:subSet subSetCount:subSetCount];
        NSData *subset = [NSData dataWithBytes:(NSUInteger *)gateCalculator.eventsInside length:sizeof(NSUInteger)*gateCalculator.countOfEventsInside];
        NSUInteger numberOfCellsInside = gateCalculator.countOfEventsInside;
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(subset, numberOfCellsInside);
        });
    });
}


+ (FGGateCalculator *)eventsInsidePolygonGateWithXParameter:(NSString *)xParShortName
                                                 yParameter:(NSString *)yParShortName
                                                   gateType:(FGGateType)gateType
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


+ (FGGateCalculator *)eventsInsidePolygonGateWithVertices:(NSArray *)vertices
                                                  fcsFile:(FGFCSFile *)fcsFile
                                              plotOptions:(NSDictionary *)plotOptions
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
    
    NSInteger xPar = [plotOptions[XParNumber] integerValue] - 1;
    NSInteger yPar = [plotOptions[YParNumber] integerValue] - 1;
    
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
                                                       gateType:(FGGateType)gateType
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
