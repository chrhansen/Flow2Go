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
    CGFloat rotationCCW = [self orientationWihtPoints:pathPoints];

    // ellipse
    self.path = [UIBezierPath bezierPathWithOvalInRect:rect];
    [self.path applyTransform:CGAffineTransformMakeRotation(rotationCCW)];
    [self.path applyTransform:CGAffineTransformMakeTranslation(center.x, center.y)];
}


- (CGFloat)orientationWihtPoints:(NSArray *)points
{
    CGPoint semiMajorPoint = [points[0] CGPointValue];
    CGPoint center         = [points[2] CGPointValue];
    CGPoint bVector = CGPointMake(semiMajorPoint.x - center.x, semiMajorPoint.y - center.y);
    return - acosf(bVector.x / sqrtf(powf(bVector.x, 2.0f) + powf(bVector.y, 2.0f)));
}


- (CGFloat)currentOrientation
{
    NSArray *points = [self getPathPoints];
    return [self orientationWihtPoints:points];
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


- (CGAffineTransform)transformForScale:(CGFloat)scale inXDir:(BOOL)isXScaling atLocation:(CGPoint)location currentOrientation:(CGFloat)orientation
{
    CGAffineTransform fromLocation = CGAffineTransformMakeTranslation(-location.x, -location.y);
    CGAffineTransform fromOrientation = CGAffineTransformMakeRotation(-orientation);
    CGAffineTransform fromOriginal = CGAffineTransformConcat(fromLocation, fromOrientation);
    
    CGAffineTransform toLocation = CGAffineTransformMakeTranslation(location.x, location.y);
    CGAffineTransform toOrientation   = CGAffineTransformMakeRotation( orientation);
    CGAffineTransform toOriginal = CGAffineTransformConcat(toOrientation, toLocation);
    
    CGFloat xScale = scale;
    CGFloat yScale = 1.0f;
    if (!isXScaling) {
        yScale = scale;
        xScale = 1.0f;
    }
    CGAffineTransform comboTransform = CGAffineTransformConcat(fromOriginal, CGAffineTransformMakeScale(xScale, yScale));
    return CGAffineTransformConcat(comboTransform, toOriginal);
}


//- (void)pinchBeganAtLocation:(CGPoint)location withScale:(CGFloat)scale
//{
//    [self.path applyTransform:[self transformForScale:scale atLocation:location]];
//}
//
//
//- (void)pinchChangedAtLocation:(CGPoint)location withScale:(CGFloat)scale
//{
//    [self.path applyTransform:[self transformForScale:scale atLocation:location]];
//}
//
//
//- (void)pinchEndedAtLocation:(CGPoint)location withScale:(CGFloat)scale
//{
//    [self.path applyTransform:[self transformForScale:scale atLocation:location]];
//}


- (void)pinchWithCentroid:(CGPoint)centroidPoint withScale:(CGFloat)scale touch1:(CGPoint)touch1Point touch2:(CGPoint)touch2Point
{
    NSArray *points = [self getPathPoints];
    CGPoint semiMajorPoint = [points[0] CGPointValue];
    CGPoint semiMinorPoint = [points[1] CGPointValue];
    CGPoint center         = [points[2] CGPointValue];
    // Semi major vector
    CGPoint semiMajorVector       = CGPointMake(semiMajorPoint.x - center.x, semiMajorPoint.y - center.y);
    CGFloat semiMajorVectorLength = sqrtf(semiMajorVector.x * semiMajorVector.x + semiMajorVector.y * semiMajorVector.y);
    CGPoint semiMajorVectorUnit   = CGPointMake(semiMajorVector.x / semiMajorVectorLength, semiMajorVector.y / semiMajorVectorLength);
    // Semi minor vector
    CGPoint semiMinorVector       = CGPointMake(semiMinorPoint.x - center.x, semiMinorPoint.y - center.y);
    CGFloat semiMinorVectorLength = sqrtf(semiMinorVector.x * semiMinorVector.x + semiMinorVector.y * semiMinorVector.y);
    CGPoint semiMinorVectorUnit   = CGPointMake(semiMinorVector.x / semiMinorVectorLength, semiMinorVector.y / semiMinorVectorLength);
    // Semi touch vector
    CGPoint touchVector           = CGPointMake(touch2Point.x - touch1Point.x, touch2Point.y - touch1Point.y);
    CGFloat touchVectorLength     = sqrtf(touchVector.x * touchVector.x + touchVector.y * touchVector.y);
    CGPoint touchVectorUnit       = CGPointMake(touchVector.x / touchVectorLength, touchVector.y / touchVectorLength);
    
    
    CGFloat minorDotProduct = touchVectorUnit.x * semiMinorVectorUnit.x + touchVectorUnit.y * semiMinorVectorUnit.y;
    CGFloat majorDotProduct = touchVectorUnit.x * semiMajorVectorUnit.x + touchVectorUnit.y * semiMajorVectorUnit.y;
    CGFloat currentOrientation = [self currentOrientation];
    CGAffineTransform pinchTransform = [self transformForScale:scale inXDir:(fabsf(minorDotProduct) <= fabsf(majorDotProduct)) atLocation:centroidPoint currentOrientation:currentOrientation];
    
    [self.path applyTransform:pinchTransform];
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
