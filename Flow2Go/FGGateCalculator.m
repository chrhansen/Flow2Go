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
#import "FGMatrixInversion.h"

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
    
    
    NSInteger xPar = [FGFCSFile parameterNumberForShortName:xParShortName inFCSFile:fcsFile] - 1;
    NSInteger yPar = [FGFCSFile parameterNumberForShortName:yParShortName inFCSFile:fcsFile] - 1;
    
    FGEllipseRepresentation ellipse;
    ellipse.halfMajorAxis = [(FGGraphPoint *)vertices[0] x];
    ellipse.halfMinorAxis = [(FGGraphPoint *)vertices[0] y];
    ellipse.rotationCCW   = [(FGGraphPoint *)vertices[1] x];
    ellipse.centerX       = [(FGGraphPoint *)vertices[2] x];
    ellipse.centerY       = [(FGGraphPoint *)vertices[2] y];
    BOOL hasInverse = NO;
    FGMatrix3 ellipseInv  = [self inverseTransformFromEllipse:ellipse hasInverse:&hasInverse];
    if (hasInverse == NO) {
        return nil;
    }
    
    FGGateCalculator *gateCalculator = [FGGateCalculator.alloc init];
    gateCalculator.eventsInside = calloc(eventsInside, sizeof(NSUInteger *));
    gateCalculator.countOfEventsInside = 0;

    FGVector3 testPoint;
    NSUInteger eventNo;
    if (subSet)
    {
        for (NSUInteger subSetNo = 0; subSetNo < subSetCount; subSetNo++)
        {
            eventNo = subSet[subSetNo];
            
            testPoint.x = (double)fcsFile.events[eventNo][xPar];
            testPoint.y = (double)fcsFile.events[eventNo][yPar];
            testPoint.z = 1.0;
            
            FGVector3 transformedPoint = [FGMatrixInversion multiplyMatrix:ellipseInv byVector:testPoint];
            double pythagorasSum = transformedPoint.x * transformedPoint.x + transformedPoint.y * transformedPoint.y;
            
            if (pythagorasSum < 1.0)
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
            testPoint.x = (double)fcsFile.events[eventNo][xPar];
            testPoint.y = (double)fcsFile.events[eventNo][yPar];
            testPoint.z = 1.0;
            
            FGVector3 transformedPoint = [FGMatrixInversion multiplyMatrix:ellipseInv byVector:testPoint];
            double pythagorasSum = transformedPoint.x * transformedPoint.x + transformedPoint.y * transformedPoint.y;
            
            if (pythagorasSum < 1.0)
            {
                gateCalculator.eventsInside[gateCalculator.countOfEventsInside] = eventNo;
                gateCalculator.countOfEventsInside += 1;
            }
        }
    }
    return gateCalculator;
}


+ (FGMatrix3)transformFromEllipse:(FGEllipseRepresentation)ellipse
{
    FGMatrix3 matrix;
    matrix.m00 =   ellipse.a * cos(ellipse.phi);
    matrix.m01 = - ellipse.b * sin(ellipse.phi);
    matrix.m02 =   0.0;
    
    matrix.m10 =   ellipse.a * sin(ellipse.phi);
    matrix.m11 =   ellipse.b * cos(ellipse.phi);
    matrix.m12 =   0.0;
    
    matrix.m20 =   0.0;
    matrix.m21 =   0.0;
    matrix.m22 =   1.0;
    return matrix;
}


+ (FGMatrix3)inverseTransformFromEllipse:(FGEllipseRepresentation)ellipse hasInverse:(BOOL *)hasInverse
{
    FGMatrix3 ellipseTransform = [self transformFromEllipse:ellipse];
    BOOL isInvertible = NO;
    FGMatrix3 inverseTransform = [FGMatrixInversion invertAffineTransform2D:ellipseTransform isInvertible:&isInvertible];
    if (isInvertible) {
        *hasInverse = YES;
        return inverseTransform;
    } else {
        *hasInverse = NO;
        return inverseTransform;
    }
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
