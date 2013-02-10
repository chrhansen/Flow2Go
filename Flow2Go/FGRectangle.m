//
//  Rectangle.m
//  Flow2Go
//
//  Created by Christian Hansen on 22/09/12.
//  Copyright (c) 2012 Christian Hansen. All rights reserved.
//

#import "FGRectangle.h"

@implementation FGRectangle



- (void)baseInit
{
    self.path = [UIBezierPath bezierPath];
    self.path.lineWidth = 2.0;
    self.path.lineCapStyle = kCGLineCapRound;
    self.strokeColor = UIColor.redColor;
    self.gateType = kGateTypeRectangle;
    self.fillColor = UIColor.redColor;
}

- (FGRectangle *)initWithVertices:(NSArray *)vertices;
{
    self = [super init];
    if (self)
    {
        [self baseInit];
        [self _drawRectanglePathWithPoints:vertices];
    }
    return self;
}


- (FGRectangle *)initWithBoundsOfContainerView:(CGRect)bounds
{
    CGFloat height = bounds.size.height;
    CGFloat width = bounds.size.width;
    
    CGPoint upperLeft = CGPointMake(width * 0.4f, height * 0.4f);
    CGPoint upperRight = CGPointMake(width * 0.6f, height * 0.4f);
    CGPoint lowerRight = CGPointMake(width * 0.6f, height * 0.6f);
    CGPoint lowerLeft = CGPointMake(width * 0.4f, height * 0.6f);
    
    NSArray *pathPoints = @[[NSValue valueWithCGPoint:upperLeft],
    [NSValue valueWithCGPoint:upperRight],
    [NSValue valueWithCGPoint:lowerRight],
    [NSValue valueWithCGPoint:lowerLeft]];
    
    return [FGRectangle.alloc initWithVertices:pathPoints];
}

- (void)_drawRectanglePathWithPoints:(NSArray *)pathPoints
{
    if (pathPoints.count < 4)
    {
        return;
    }
    CGPoint upperLeft = [pathPoints[0] CGPointValue];
    CGPoint lowerRight = [pathPoints[2] CGPointValue];
    
    CGRect rect = CGRectMake(upperLeft.x, upperLeft.y, fabsf(lowerRight.x - upperLeft.x), fabsf(lowerRight.y - upperLeft.y));
    
    // rectangle
    self.path = [UIBezierPath bezierPathWithRect:rect];
    NSLog(@"rect points after creation: %@", [self getPathPoints]);

}


#pragma mark - Public methods overwritten

- (BOOL)isContentsUnderPoint:(CGPoint)point
{
    return [self.path containsPoint:point];
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


#define HOOK_SIZE 8.0

- (UIBezierPath *)_hookAtPoint:(CGPoint)point
{
    CGRect rect = CGRectMake(point.x - HOOK_SIZE * 0.5, point.y - HOOK_SIZE * 0.5, HOOK_SIZE, HOOK_SIZE);
    return [UIBezierPath bezierPathWithOvalInRect: rect];
}

- (void)showDragableHooks
{
    self.hooks = NSMutableArray.array;
    NSArray *points = [self getPathPoints];
    for (NSValue *aValue in points)
    {
        [self.hooks addObject:[self _hookAtPoint:aValue.CGPointValue]];
    }
}


- (void)hideDragableHooks
{
    [self.hooks removeAllObjects];
    self.hooks = nil;
}


- (void)movePathElementToPoint:(CGPoint)point
{
    NSValue *valuePoint = [NSValue valueWithCGPoint:point];
    CGPathApply(self.path.CGPath, (__bridge void *)(valuePoint), Flow2GoCGPathPointMoveFunction);
}


void Flow2GoCGPathPointMoveFunction (void *info, const CGPathElement *element)
{
    NSValue *valuePoint = (__bridge NSValue *)info;
    
    CGPoint *points = element->points;
    CGPathElementType type = element->type;
    
    switch(type)
    {
        case kCGPathElementMoveToPoint: // contains 1 point
            points[0] = valuePoint.CGPointValue;
            break;
            
        default:
            break;
    }
}

@end
