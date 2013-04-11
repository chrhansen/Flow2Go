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
    CGFloat width  = bounds.size.width;
    
    CGPoint center         = CGPointMake(width * 0.5f, height * 0.5f);
    CGPoint semiMajorPoint = CGPointMake(center.x + 100.0f, center.y + 40.0f);
    CGPoint semiMinorPoint = CGPointMake(center.x, center.y + 40.0f);

    NSArray *pathPoints = @[[NSValue valueWithCGPoint:semiMajorPoint],
                            [NSValue valueWithCGPoint:semiMinorPoint],
                            [NSValue valueWithCGPoint:center]];
    
    return [FGEllipse.alloc initWithVertices:pathPoints];
}

- (void)_createEllipsePathWithPoints:(NSArray *)pathPoints
{
    if (pathPoints.count < 3) {
        return;
    }
    CGPoint semiMajorPoint =  [pathPoints[0] CGPointValue];
    CGPoint semiMinorPoint =  [pathPoints[1] CGPointValue];
    CGPoint center         =  [pathPoints[2] CGPointValue];
    
    CGPoint abAxis;
    abAxis.x = sqrtf(powf(center.x - semiMajorPoint.x, 2.0f) + powf(center.y - semiMajorPoint.y, 2.0f));
    abAxis.y = sqrtf(powf(center.x - semiMinorPoint.x, 2.0f) + powf(center.y - semiMinorPoint.y, 2.0f));
    CGRect rect = CGRectMake(-abAxis.x, -abAxis.y, abAxis.x * 2.0f, abAxis.y * 2.0f);
    
    // Get rotation of ellipse
    CGPoint bVector = CGPointMake(semiMajorPoint.x - center.x, semiMajorPoint.y - center.y);
    CGFloat rotationCCW = - acosf(bVector.x / sqrtf(powf(bVector.x, 2.0f) + powf(bVector.y, 2.0f)));

    // ellipse
    self.path = [UIBezierPath bezierPathWithOvalInRect:rect];
    [self.path applyTransform:CGAffineTransformMakeRotation(rotationCCW)];
    [self.path applyTransform:CGAffineTransformMakeTranslation(center.x, center.y)];
    NSLog(@"ellipse points after creation: %@", [self getPathPoints]);
}


#pragma mark - Public methods overwritten

- (NSArray *)getPathPoints
{
    NSArray *pathPoints   = [super getPathPoints];
    CGPoint point0 = [pathPoints[0] CGPointValue];
    CGPoint point3 = [pathPoints[3] CGPointValue];
    CGPoint point6 = [pathPoints[6] CGPointValue];
    
    CGPoint center   = CGPointMake((point6.x - point0.x) * 0.5f + point0.x, (point6.y - point0.y) * 0.5f + point0.y);
    NSArray *ellipse = @[[NSValue valueWithCGPoint:point0], [NSValue valueWithCGPoint:point3], [NSValue valueWithCGPoint:center]];
    
    NSLog(@"Ellipse points: %@", ellipse);
    return ellipse;
}


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
