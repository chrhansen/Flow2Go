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
    if (self) {
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
    CGPoint semiMajorPoint = CGPointMake(center.x + width * 0.2f, center.y);
    CGPoint semiMinorPoint = CGPointMake(center.x, center.y + height * 0.1f);

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
    NSArray *abAxes   = [self axesWithEllipsePoints:pathPoints normalize:NO];
    CGPoint center    = [pathPoints[2] CGPointValue];
    CGFloat semiMajor = [self vectorLength:[abAxes[0] CGPointValue]];
    CGFloat semiMinor = [self vectorLength:[abAxes[1] CGPointValue]];
    
    CGRect rect = CGRectMake(-semiMajor, -semiMinor, semiMajor * 2.0f, semiMinor * 2.0f);
    
    // Get rotation of ellipse
    CGFloat rotationCCW = [self orientationWithPoints:pathPoints];
    
    // ellipse
    self.path = [UIBezierPath bezierPathWithOvalInRect:rect];
    [self.path applyTransform:CGAffineTransformMakeRotation(-rotationCCW)];
    [self.path applyTransform:CGAffineTransformMakeTranslation(center.x, center.y)];
}



- (NSArray *)axesWithEllipsePoints:(NSArray *)pathPoints normalize:(BOOL)shouldNormalize
{
    CGPoint semiMajorPoint =  [pathPoints[0] CGPointValue];
    CGPoint semiMinorPoint =  [pathPoints[1] CGPointValue];
    CGPoint center         =  [pathPoints[2] CGPointValue];
    
    CGPoint semiMajorVector = CGPointMake(semiMajorPoint.x - center.x, semiMajorPoint.y - center.y);
    CGPoint semiMinorVector = CGPointMake(semiMinorPoint.x - center.x, semiMinorPoint.y - center.y);
    
    if (shouldNormalize) {
        semiMajorVector = [self normalizeVector:semiMajorVector];
        semiMinorVector = [self normalizeVector:semiMinorVector];
    }
    return @[[NSValue valueWithCGPoint:semiMajorVector], [NSValue valueWithCGPoint:semiMinorVector]];
}


#define TWO_PI 2.0f * (CGFloat)M_PI

- (CGFloat)orientationWithPoints:(NSArray *)points
{
    CGPoint semiMajorPoint = [points[0] CGPointValue];
    CGPoint center         = [points[2] CGPointValue];
    CGPoint bVector = CGPointMake(semiMajorPoint.x - center.x, semiMajorPoint.y - center.y);

    CGFloat angle = acosf(bVector.x / [self vectorLength:bVector]);
    
    if (bVector.y > 0.0f) {
        angle = TWO_PI - angle;
    }
    return angle;
}


- (CGFloat)currentOrientation
{
    NSArray *points = [self getPathPoints];
    return [self orientationWithPoints:points];
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
    
    return ellipse;
}

- (BOOL)isContentsUnderPoint:(CGPoint)point
{
    return [self.path containsPoint:point];
}


- (CGAffineTransform)transformForScale:(CGFloat)scale inXDir:(BOOL)isXScaling atLocation:(CGPoint)location currentOrientation:(CGFloat)orientation
{
    CGAffineTransform fromLocation    = CGAffineTransformMakeTranslation(-location.x, -location.y);
    CGAffineTransform fromOrientation = CGAffineTransformMakeRotation( orientation);
    CGAffineTransform fromOriginal    = CGAffineTransformConcat(fromLocation, fromOrientation);
    
    CGAffineTransform toOrientation   = CGAffineTransformMakeRotation( -orientation);
    CGAffineTransform toLocation      = CGAffineTransformMakeTranslation(location.x, location.y);
    CGAffineTransform toOriginal      = CGAffineTransformConcat(toOrientation, toLocation);
    
    CGFloat xScale = scale;
    CGFloat yScale = 1.0f;
    if (!isXScaling) {
        yScale = scale;
        xScale = 1.0f;
    }
    CGAffineTransform comboTransform = CGAffineTransformConcat(fromOriginal, CGAffineTransformMakeScale(xScale, yScale));
    return CGAffineTransformConcat(comboTransform, toOriginal);
}

#define DEGREES_TO_RADIANS(x) ((CGFloat)M_PI * x / 180.0f)
#define RADIANS_TO_DEGREES(x) (180.0f * x / (CGFloat)M_PI)

- (void)pinchWithCentroid:(CGPoint)centroidPoint scale:(CGFloat)scale touchPoint1:(CGPoint)touch1Point touchPoint2:(CGPoint)touch2Point
{
    NSArray *points = [self getPathPoints];

    NSArray *unitABAxes = [self axesWithEllipsePoints:points normalize:YES];
    CGPoint semiMajorVectorUnit = [unitABAxes[0] CGPointValue];
    CGPoint semiMinorVectorUnit = [unitABAxes[1] CGPointValue];
    CGPoint touchVectorUnit     = [self normalizeVector:CGPointMake(touch2Point.x - touch1Point.x, touch2Point.y - touch1Point.y)];
    
    CGFloat minorDotProduct = touchVectorUnit.x * semiMinorVectorUnit.x + touchVectorUnit.y * semiMinorVectorUnit.y;
    CGFloat majorDotProduct = touchVectorUnit.x * semiMajorVectorUnit.x + touchVectorUnit.y * semiMajorVectorUnit.y;
    CGFloat currentOrientation = [self currentOrientation];    
    
    CGAffineTransform pinchTransform = [self transformForScale:scale inXDir:(fabsf(minorDotProduct) < fabsf(majorDotProduct)) atLocation:centroidPoint currentOrientation:currentOrientation];
    [self.path applyTransform:pinchTransform];
}


- (CGAffineTransform)transformForRotation:(CGFloat)angle atLocation:(CGPoint)location
{
    CGAffineTransform toCenter = CGAffineTransformMakeTranslation(-location.x, -location.y);
    CGAffineTransform toLocation = CGAffineTransformMakeTranslation(location.x, location.y);
    CGAffineTransform comboTransform = CGAffineTransformConcat(toCenter, CGAffineTransformMakeRotation(angle));
    return CGAffineTransformConcat(comboTransform, toLocation);
}

- (void)rotationtAtLocation:(CGPoint)location withAngle:(CGFloat)angle
{
    [self.path applyTransform:[self transformForRotation:angle atLocation:location]];
}

@end
