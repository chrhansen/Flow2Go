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
            return [FGGateCalculator eventsInsidePolygonGateWithGateData:gateData fcsFile:fcsFile subSet:subSet subSetCount:subSetCount];
            break;
            
        case kGateTypeEllipse:
            return [FGGateCalculator eventsInsideEllipseGateWithGateData:gateData fcsFile:fcsFile subSet:subSet subSetCount:subSetCount];
            break;
            
        case kGateTypeQuadrant:
            return nil;
            break;
            
        case kGateTypeSingleRange:
            return [FGGateCalculator eventsInsideSingleRangeGateWithGateData:gateData fcsFile:fcsFile subSet:subSet subSetCount:subSetCount];
            break;
            
        case kGateTypeTripleRange:
            return nil;
            break;
            
        default:
            break;
    }
    return nil;
}


+ (FGGateCalculator *)eventsInsidePolygonGateWithGateData:(NSDictionary *)gateData
                                                  fcsFile:(FGFCSFile *)fcsFile
                                                   subSet:(NSUInteger *)subSet
                                              subSetCount:(NSUInteger)subSetCount
{
    NSInteger eventsInside = subSetCount;
    if (!subSet) eventsInside = fcsFile.data.noOfEvents;
    
    FGGateCalculator *gateCalculator = [FGGateCalculator.alloc init];
    gateCalculator.eventsInside = calloc(eventsInside, sizeof(NSUInteger *));
    gateCalculator.countOfEventsInside = 0;
    
    NSInteger xPar = [gateData[GateXParNumber] integerValue] - 1;
    NSInteger yPar = [gateData[GateYParNumber] integerValue] - 1;
    FGAxisType xAxisType = [gateData[XAxisType] integerValue];
    FGAxisType yAxisType = [gateData[YAxisType] integerValue];
    NSArray *vertices = gateData[Vertices];
    NSArray *correctedVertices = [self correctVertices:vertices forXScaleType:xAxisType yScaleType:yAxisType];

    FGPlotPoint plotPoint;
    NSUInteger eventNo;
    
    for (NSUInteger index = 0; index < eventsInside; index++)
    {
        eventNo = index;
        if (subSet) eventNo = subSet[index];
        
        plotPoint.xVal = fcsFile.data.events[eventNo][xPar];
        plotPoint.yVal = fcsFile.data.events[eventNo][yPar];
        
        if (xAxisType == kAxisTypeLogarithmic) plotPoint.xVal = log10(plotPoint.xVal);
        if (yAxisType == kAxisTypeLogarithmic) plotPoint.yVal = log10(plotPoint.yVal);
        
        if ([self _point:plotPoint insidePolygon:correctedVertices])
        {
            gateCalculator.eventsInside[gateCalculator.countOfEventsInside] = eventNo;
            gateCalculator.countOfEventsInside += 1;
        }
    }
    return gateCalculator;
}


+ (NSArray *)correctVertices:(NSArray *)vertices forXScaleType:(FGAxisType)xScaleType yScaleType:(FGAxisType)yScaleType
{
    NSMutableArray *correctedVertices = [NSMutableArray arrayWithCapacity:vertices.count];
    for (FGGraphPoint *graphPoint in vertices) {
        FGGraphPoint *modifiedGraphPoint = [[FGGraphPoint alloc] init];
        modifiedGraphPoint.x = (xScaleType == kAxisTypeLogarithmic) ? log10(graphPoint.x) : graphPoint.x;
        modifiedGraphPoint.y = (yScaleType == kAxisTypeLogarithmic) ? log10(graphPoint.y) : graphPoint.y;
        [correctedVertices addObject:modifiedGraphPoint];
    }
    return correctedVertices;
}


+ (FGGateCalculator *)eventsInsideSingleRangeGateWithGateData:(NSDictionary *)gateData
                                                      fcsFile:(FGFCSFile *)fcsFile
                                                       subSet:(NSUInteger *)subSet
                                                  subSetCount:(NSUInteger)subSetCount
{
    NSInteger eventsInside = subSetCount;
    if (!subSet) eventsInside = fcsFile.data.noOfEvents;
    
    
    FGGateCalculator *gateCalculator = [FGGateCalculator.alloc init];
    gateCalculator.eventsInside = calloc(eventsInside, sizeof(NSUInteger *));
    gateCalculator.countOfEventsInside = 0;
    
    NSInteger xPar = [gateData[GateXParNumber] integerValue] - 1;
    NSArray *vertices = gateData[Vertices];

    double xMin = [(FGGraphPoint *)vertices[0] x];
    double xMax = [(FGGraphPoint *)vertices[1] x];
    double plotPoint;
    
    NSUInteger eventNo;
    for (NSUInteger index = 0; index < eventsInside; index++)
    {
        eventNo = index;
        if (subSet) eventNo = subSet[index];
        
        plotPoint = fcsFile.data.events[eventNo][xPar];
        
        if (plotPoint > xMin
            && plotPoint < xMax) {
            gateCalculator.eventsInside[gateCalculator.countOfEventsInside] = eventNo;
            gateCalculator.countOfEventsInside += 1;
        }
    }
    return gateCalculator;
}


+ (FGGateCalculator *)eventsInsideEllipseGateWithGateData:(NSDictionary *)gateData
                                                  fcsFile:(FGFCSFile *)fcsFile
                                                   subSet:(NSUInteger *)subSet
                                              subSetCount:(NSUInteger)subSetCount
{
    NSInteger eventsInside = subSetCount;
    if (!subSet) eventsInside = fcsFile.data.noOfEvents;
    
    NSInteger xPar = [gateData[GateXParNumber] integerValue] - 1;
    NSInteger yPar = [gateData[GateYParNumber] integerValue] - 1;
    FGAxisType xAxisType = [gateData[XAxisType] integerValue];
    FGAxisType yAxisType = [gateData[YAxisType] integerValue];
    NSArray *vertices = gateData[Vertices];
        
    FGEllipseRepresentation ellipse = [self ellipseFromPoints:vertices];
    
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
    for (NSUInteger index = 0; index < eventsInside; index++)
    {
        eventNo = index;
        if (subSet) eventNo = subSet[index];
        
        testPoint.x = (double)fcsFile.data.events[eventNo][xPar];
        testPoint.y = (double)fcsFile.data.events[eventNo][yPar];
        testPoint.z = 1.0;
        
        if (xAxisType == kAxisTypeLogarithmic) testPoint.x = log10(testPoint.x);
        if (yAxisType == kAxisTypeLogarithmic) testPoint.y = log10(testPoint.y);
        
        FGVector3 transformedPoint = [FGMatrixInversion multiplyMatrix:ellipseInv byVector:testPoint];
        double pythagorasSum = transformedPoint.x * transformedPoint.x + transformedPoint.y * transformedPoint.y;
        
        if (pythagorasSum < 1.0)
        {
            gateCalculator.eventsInside[gateCalculator.countOfEventsInside] = eventNo;
            gateCalculator.countOfEventsInside += 1;
        }
    }
    return gateCalculator;
}


+ (FGEllipseRepresentation)ellipseFromPoints:(NSArray *)points
{
    FGGraphPoint *semiMajorAxisPoint = points[0];
    FGGraphPoint *semiMinorAxisPoint = points[1];
    FGGraphPoint *center             = points[2];
    
    FGGraphPoint *centerToSemiMajorAxisPoint = [FGGraphPoint pointWithX:(semiMajorAxisPoint.x - center.x) andY:(semiMajorAxisPoint.y - center.y)];
    
    FGEllipseRepresentation ellipse;
    ellipse.halfMajorAxis = sqrt(pow(centerToSemiMajorAxisPoint.x, 2.0) + pow(centerToSemiMajorAxisPoint.y, 2.0));
    ellipse.halfMinorAxis = sqrt(pow(semiMinorAxisPoint.x - center.x, 2.0) + pow(semiMinorAxisPoint.y - center.y, 2.0));
    double angle = acos(centerToSemiMajorAxisPoint.x / sqrt(pow(centerToSemiMajorAxisPoint.x, 2.0) + pow(centerToSemiMajorAxisPoint.y, 2.0)));
    ellipse.rotationCCW = (centerToSemiMajorAxisPoint.y > 0.0) ? angle : M_PI - angle;
    ellipse.centerX = center.x;
    ellipse.centerY = center.y;
    
    return ellipse;
}

+ (FGMatrix3)transformFromEllipse:(FGEllipseRepresentation)ellipse
{
    FGMatrix3 matrix;
    matrix.m00 =   ellipse.a * cos(ellipse.phi);
    matrix.m01 = - ellipse.b * sin(ellipse.phi);
    matrix.m02 =   ellipse.centerX;
    
    matrix.m10 =   ellipse.a * sin(ellipse.phi);
    matrix.m11 =   ellipse.b * cos(ellipse.phi);
    matrix.m12 =   ellipse.centerY;
    
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
