//
//  Polygon.m
//  ShapeTest
//
//  Created by Christian Hansen on 15/09/12.
//  Copyright (c) 2012 Calcul8.it. All rights reserved.
//

#import "Polygon.h"



@implementation Polygon
@synthesize path = _path;

#define REQUIRED_GAP 30.0

- (void)baseInit
{
    self.path = [UIBezierPath bezierPath];
    self.path.lineWidth = 2.0;
    self.path.lineCapStyle = kCGLineCapRound;
    self.strokeColor = UIColor.redColor;
    self.fillColor = UIColor.redColor;
}

- (Polygon *)initWithVertices:(NSArray *)vertices;
{
    self = [super init];
    if (self)
    {
        [self baseInit];
        self.gateType = kGateTypePolygon;
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

@end
