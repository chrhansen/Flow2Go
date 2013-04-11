//
//  Graphic.m
//  ShapeTest
//
//  Created by Christian Hansen on 15/09/12.
//  Copyright (c) 2012 Calcul8.it. All rights reserved.
//

#import "FGGateGraphic.h"


@implementation FGGateGraphic

- (void)baseInit
{
    self.path = [UIBezierPath bezierPath];
    self.path.lineWidth = 2.0;
    self.path.lineCapStyle = kCGLineCapRound;
    self.strokeColor = UIColor.redColor;
    self.fillColor = UIColor.redColor;
    self.hookColor = UIColor.blueColor;
}


- (FGGateGraphic *)initWithVertices:(NSArray *)vertices
{
    // override in subclass
    self = [super init];
    if (self)
    {
        [self baseInit];
    }
    return self;
}

- (FGGateGraphic *)initWithBoundsOfContainerView:(CGRect)bounds
{
    // override in subclass
    self = [super init];
    if (self)
    {
        [self baseInit];
    }
    return self;
}


- (void)showDragableHooks
{
    // Override in subclass
}

- (void)hideDragableHooks
{
    // Override in subclass
}


- (BOOL)isContentsUnderPoint:(CGPoint)point
{
    // Just check against the graphic's bounds.
    return CGRectContainsPoint(self.path.bounds, point);
}

- (void)panBeganAtPoint:(CGPoint)beginPoint
{
    // Override in subclass
}


- (void)panChangedToPoint:(CGPoint)nextPoint
{
    // Override in subclass
}


- (void)panEndedAtPoint:(CGPoint)endPoint
{
    // Override in subclass
}


- (void)pinchBeganAtLocation:(CGPoint)location withScale:(CGFloat)scale
{
    // Override in subclass
}


- (void)pinchChangedAtLocation:(CGPoint)location withScale:(CGFloat)scale
{
    // Override in subclass
}


- (void)pinchEndedAtLocation:(CGPoint)location withScale:(CGFloat)scale
{
    // Override in subclass
}


- (void)rotationBeganAtLocation:(CGPoint)location withAngle:(CGFloat)angle
{
    // Override in subclass
}


- (void)rotationChangedAtLocation:(CGPoint)location withAngle:(CGFloat)angle
{
    // Override in subclass
}


- (void)rotationEndedAtLocation:(CGPoint)location withAngle:(CGFloat)angle
{
    // Override in subclass
}


- (NSArray *)getPathPoints
{
    NSMutableArray *bezierPoints = [NSMutableArray array];
    CGPathApply(self.path.CGPath, (__bridge void *)(bezierPoints), Flow2GoCGPathApplierFunc);

    return [NSArray arrayWithArray:bezierPoints];
}


void Flow2GoCGPathApplierFunc (void *info, const CGPathElement *element)
{
    NSMutableArray *bezierPoints = (__bridge NSMutableArray *)info;
    
    CGPoint *points = element->points;
    CGPathElementType type = element->type;
    
    switch(type)
    {
        case kCGPathElementMoveToPoint: // contains 1 point
            [bezierPoints addObject:[NSValue valueWithCGPoint:points[0]]];
            break;
            
        case kCGPathElementAddLineToPoint: // contains 1 point
            [bezierPoints addObject:[NSValue valueWithCGPoint:points[0]]];
            break;
            
        case kCGPathElementAddQuadCurveToPoint: // contains 2 points
            [bezierPoints addObject:[NSValue valueWithCGPoint:points[0]]];
            [bezierPoints addObject:[NSValue valueWithCGPoint:points[1]]];
            break;
            
        case kCGPathElementAddCurveToPoint: // contains 3 points
            [bezierPoints addObject:[NSValue valueWithCGPoint:points[0]]];
            [bezierPoints addObject:[NSValue valueWithCGPoint:points[1]]];
            [bezierPoints addObject:[NSValue valueWithCGPoint:points[2]]];
            break;
            
        case kCGPathElementCloseSubpath: // contains no point
            break;
    }
}


@end
