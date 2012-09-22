//
//  Rectangle.m
//  Flow2Go
//
//  Created by Christian Hansen on 22/09/12.
//  Copyright (c) 2012 Christian Hansen. All rights reserved.
//

#import "Rectangle.h"

@implementation Rectangle



- (void)baseInit
{
    self.path = [UIBezierPath bezierPath];
    self.path.lineWidth = 2.0;
    self.path.lineCapStyle = kCGLineCapRound;
    self.strokeColor = UIColor.redColor;
    self.gateType = kGateTypeRectangle;
    self.fillColor = UIColor.redColor;
}

- (Rectangle *)initWithVertices:(NSArray *)vertices;
{
    self = [super init];
    if (self)
    {
        [self baseInit];
        [self _drawRectanglePathWithPoints:vertices];
    }
    return self;
}


- (Rectangle *)initWithBoundsOfContainerView:(CGRect)bounds
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
    
    return [Rectangle.alloc initWithVertices:pathPoints];
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

@end
