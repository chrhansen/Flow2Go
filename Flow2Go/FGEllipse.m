//
//  Ellipse.m
//  Flow2Go
//
//  Created by Christian Hansen on 23/09/12.
//  Copyright (c) 2012 Christian Hansen. All rights reserved.
//

#import "FGEllipse.h"

@implementation FGEllipse



- (void)baseInit
{
    self.path = [UIBezierPath bezierPath];
    self.path.lineWidth = 2.0;
    self.path.lineCapStyle = kCGLineCapRound;
    self.strokeColor = UIColor.redColor;
    self.gateType = kGateTypeEllipse;
    self.fillColor = UIColor.redColor;
}

- (FGEllipse *)initWithVertices:(NSArray *)vertices;
{
    self = [super init];
    if (self)
    {
        [self baseInit];
        [self _createEllipsePathWithPoints:vertices];
    }
    return self;
}


- (FGEllipse *)initWithBoundsOfContainerView:(CGRect)bounds
{
    CGFloat height = bounds.size.height;
    CGFloat width = bounds.size.width;
    
    CGPoint abAxis      = CGPointMake(width * 0.2f, height * 0.1f);
    CGFloat rotationCCW = -M_PI_4;
    CGPoint center      = CGPointMake(width * 0.5f, height * 0.5f);

    NSArray *pathPoints = @[[NSValue valueWithCGPoint:abAxis],
                            [NSNumber numberWithFloat:rotationCCW],
                            [NSValue valueWithCGPoint:center]];
    
    return [FGEllipse.alloc initWithVertices:pathPoints];
}

- (void)_createEllipsePathWithPoints:(NSArray *)pathPoints
{
    if (pathPoints.count < 3) {
        return;
    }
    
    CGPoint abAxis      = [pathPoints[0] CGPointValue];
    CGFloat rotationCCW = [pathPoints[1] floatValue];
    CGPoint center      = [pathPoints[2] CGPointValue];

    CGRect rect = CGRectMake(-abAxis.x, -abAxis.y, abAxis.x * 2.0f, abAxis.y * 2.0f);
    
    // ellipse
    self.path = [UIBezierPath bezierPathWithOvalInRect:rect];
    [self.path applyTransform:CGAffineTransformMakeRotation(rotationCCW)];
    [self.path applyTransform:CGAffineTransformMakeTranslation(center.x, center.y)];
    NSLog(@"ellipse points after creation: %@", [self getPathPoints]);
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
