//
//  SingleRange.m
//  Flow2Go
//
//  Created by Christian Hansen on 21/09/12.
//  Copyright (c) 2012 Christian Hansen. All rights reserved.
//

#import "FGSingleRange.h"

@implementation FGSingleRange

@synthesize path = _path;

- (void)baseInit
{
    self.path = [UIBezierPath bezierPath];
    self.path.lineWidth = 2.0;
    self.path.lineCapStyle = kCGLineCapRound;
    self.strokeColor = UIColor.redColor;
    self.gateType = kGateTypeSingleRange;
}

- (FGSingleRange *)initWithVertices:(NSArray *)vertices;
{
    self = [super init];
    if (self)
    {
        [self baseInit];
        [self _drawSingleRangePathWithPoints:vertices];
    }
    return self;
}

#define GATEHEIGHT 50

- (void)_drawSingleRangePathWithPoints:(NSArray *)pathPoints
{
    if (pathPoints.count < 2)
    {
        return;
    }
    CGPoint leftPoint = [pathPoints[0] CGPointValue];
    CGPoint rightPoint = [pathPoints[1] CGPointValue];
    
    // horizontal line
    [self.path moveToPoint:CGPointMake(leftPoint.x, leftPoint.y)];
    [self.path addLineToPoint:CGPointMake(rightPoint.x, leftPoint.y)];
    
    // left line
    [self.path moveToPoint:CGPointMake(leftPoint.x, leftPoint.y + GATEHEIGHT*0.5)];
    [self.path addLineToPoint:CGPointMake(leftPoint.x, leftPoint.y - GATEHEIGHT*0.5)];

    // right line
    [self.path moveToPoint:CGPointMake(rightPoint.x, leftPoint.y + GATEHEIGHT*0.5)];
    [self.path addLineToPoint:CGPointMake(rightPoint.x, leftPoint.y - GATEHEIGHT*0.5)];
}


- (CGFloat)distanceFrom:(CGPoint)point1 toPoint:(CGPoint)point2
{
    CGFloat dX = point2.x - point1.x;
    CGFloat dY = point2.y - point1.y;
    return sqrtf(dX * dX + dY * dY);
}




#pragma mark - Public methods overwritten

- (BOOL)isContentsUnderPoint:(CGPoint)point
{
    return CGRectContainsPoint(self.path.bounds, point);
}



- (void)panBeganAtPoint:(CGPoint)beginPoint
{
    // pan began
}


- (void)panChangedToPoint:(CGPoint)nextPoint
{
    // pan changed
}


- (void)panEndedAtPoint:(CGPoint)endPoint
{
    // pan changed
}

- (CGAffineTransform)xTransformForScale:(CGFloat)scale atLocation:(CGPoint)location
{
    CGAffineTransform toCenter = CGAffineTransformMakeTranslation(-location.x, -location.y);
    CGAffineTransform toLocation = CGAffineTransformMakeTranslation(location.x, location.y);
    CGAffineTransform comboTransform = CGAffineTransformConcat(toCenter, CGAffineTransformMakeScale(scale, 1.0f));
    return CGAffineTransformConcat(comboTransform, toLocation);
}


- (void)pinchBeganAtLocation:(CGPoint)location withScale:(CGFloat)scale
{
    [self.path applyTransform:[self xTransformForScale:scale atLocation:location]];
}


- (void)pinchChangedAtLocation:(CGPoint)location withScale:(CGFloat)scale
{
    [self.path applyTransform:[self xTransformForScale:scale atLocation:location]];
}


- (void)pinchEndedAtLocation:(CGPoint)location withScale:(CGFloat)scale
{
    [self.path applyTransform:[self xTransformForScale:scale atLocation:location]];
}


@end
