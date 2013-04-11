//
//  Polygon.m
//  ShapeTest
//
//  Created by Christian Hansen on 15/09/12.
//  Copyright (c) 2012 Calcul8.it. All rights reserved.
//

#import "FGPolygon.h"



@implementation FGPolygon
@synthesize path = _path;

#define REQUIRED_GAP 30.0

- (void)baseInit
{
    self.path = [UIBezierPath bezierPath];
    self.path.lineWidth = 2.0;
    self.path.lineCapStyle = kCGLineCapRound;
    self.strokeColor = UIColor.redColor;
    self.gateType = kGateTypePolygon;
    self.fillColor = UIColor.redColor;
}

- (id)init
{
    self = [super init];
    if (self)
    {
        [self baseInit];
    }
    return self;
}


- (FGPolygon *)initWithVertices:(NSArray *)vertices;
{
    self = [super init];
    if (self)
    {
        [self baseInit];
        [self _drawPolygonPathWithPoints:vertices];
    }
    return self;
}

- (void)_drawPolygonPathWithPoints:(NSArray *)pathPoints
{
    if (pathPoints.count > 2)
    {
        [self _startPolygonPathAtPoint:[pathPoints[0] CGPointValue]];
        
        for (NSUInteger i = 1; i < pathPoints.count; i++)
        {
            [self _extendPolygonPathWithPoint:[pathPoints[i] CGPointValue]];
        }
        [self _endPath];
    }
}


- (CGFloat)distanceFrom:(CGPoint)point1 toPoint:(CGPoint)point2
{
    CGFloat dX = point2.x - point1.x;
    CGFloat dY = point2.y - point1.y;
    return sqrtf(dX * dX + dY * dY);
}



- (void)_startPolygonPathAtPoint:(CGPoint)startPoint
{
    [self.path moveToPoint:startPoint];
}

- (void)_extendPolygonPathWithPoint:(CGPoint)nextPoint
{
    [self.path addLineToPoint:nextPoint];
}

- (void)_endPath
{
    [self.path closePath];
}



#pragma mark - Public methods overwritten

- (BOOL)isContentsUnderPoint:(CGPoint)point
{
    return [self.path containsPoint:point];
}



- (void)panBeganAtPoint:(CGPoint)beginPoint
{
    [self _startPolygonPathAtPoint:beginPoint];
}


- (void)panChangedToPoint:(CGPoint)nextPoint
{
    CGFloat distance = [self distanceFrom:self.path.currentPoint toPoint:nextPoint];
    if (distance > REQUIRED_GAP)
    {
        [self _extendPolygonPathWithPoint:nextPoint];
    }
}


- (void)panEndedAtPoint:(CGPoint)endPoint
{
    [self _endPath];
}


- (CGAffineTransform)transformForScale:(CGFloat)scale atLocation:(CGPoint)location
{
    CGAffineTransform toCenter = CGAffineTransformMakeTranslation(-location.x, -location.y);
    CGAffineTransform toLocation = CGAffineTransformMakeTranslation(location.x, location.y);
    CGAffineTransform comboTransform = CGAffineTransformConcat(toCenter, CGAffineTransformMakeScale(scale, scale));
    return CGAffineTransformConcat(comboTransform, toLocation);
}

- (void)pinchBeganAtLocation:(CGPoint)location withScale:(CGFloat)scale
{
    [self.path applyTransform:[self transformForScale:scale atLocation:location]];
}


- (void)pinchChangedAtLocation:(CGPoint)location withScale:(CGFloat)scale
{
    [self.path applyTransform:[self transformForScale:scale atLocation:location]];
}


- (void)pinchEndedAtLocation:(CGPoint)location withScale:(CGFloat)scale
{
    [self.path applyTransform:[self transformForScale:scale atLocation:location]];
}


- (CGAffineTransform)transformForRotation:(CGFloat)angle atLocation:(CGPoint)location
{
    CGAffineTransform toCenter = CGAffineTransformMakeTranslation(-location.x, -location.y);
    CGAffineTransform toLocation = CGAffineTransformMakeTranslation(location.x, location.y);
    CGAffineTransform comboTransform = CGAffineTransformConcat(toCenter, CGAffineTransformMakeRotation(angle));
    return CGAffineTransformConcat(comboTransform, toLocation);
}


- (void)rotationBeganAtLocation:(CGPoint)location withAngle:(CGFloat)angle
{
    [self.path applyTransform:[self transformForRotation:angle atLocation:location]];
}


- (void)rotationChangedAtLocation:(CGPoint)location withAngle:(CGFloat)angle
{
    [self.path applyTransform:[self transformForRotation:angle atLocation:location]];
}


- (void)rotationEndedAtLocation:(CGPoint)location withAngle:(CGFloat)angle
{
    [self.path applyTransform:[self transformForRotation:angle atLocation:location]];
}

@end
