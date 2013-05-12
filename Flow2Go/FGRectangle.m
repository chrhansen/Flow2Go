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
    self.fillColor = nil; //UIColor.redColor;
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
    [self _startPathAtPoint:[pathPoints[0] CGPointValue]];
    for (NSUInteger i = 1; i < pathPoints.count; i++) {
        [self _extendPathWithPoint:[pathPoints[i] CGPointValue]];
    }
    [self _endPath];
}


- (void)_startPathAtPoint:(CGPoint)startPoint
{
    [self.path moveToPoint:startPoint];
}

- (void)_extendPathWithPoint:(CGPoint)nextPoint
{
    [self.path addLineToPoint:nextPoint];
}

- (void)_endPath
{
    [self.path closePath];
}

#define TWO_PI 2.0f * (CGFloat)M_PI

- (CGFloat)orientationWithPoints:(NSArray *)points
{
    CGPoint upperLeft  = [points[0] CGPointValue];
    CGPoint upperRight = [points[1] CGPointValue];
    CGPoint bVector = CGPointMake(upperRight.x - upperLeft.x, upperRight.y - upperLeft.y);
    
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
    
    CGPoint point0 = [points[0] CGPointValue];
    CGPoint point1 = [points[1] CGPointValue];
    CGPoint point2 = [points[2] CGPointValue];
    
    CGPoint vector01 = [self normalizeVector:CGPointMake(point1.x - point0.x, point1.y - point0.y)];
    CGPoint vector12 = [self normalizeVector:CGPointMake(point2.x - point1.x, point2.y - point1.y)];
    CGPoint touchVectorUnit     = [self normalizeVector:CGPointMake(touch2Point.x - touch1Point.x, touch2Point.y - touch1Point.y)];
    
    CGFloat vector01Dot = touchVectorUnit.x * vector01.x + touchVectorUnit.y * vector01.y;
    CGFloat vector12Dot = touchVectorUnit.x * vector12.x + touchVectorUnit.y * vector12.y;
    CGFloat currentOrientation = [self currentOrientation];
    
    CGAffineTransform pinchTransform = [self transformForScale:scale inXDir:(fabsf(vector01Dot) > fabsf(vector12Dot)) atLocation:centroidPoint currentOrientation:currentOrientation];
    [self.path applyTransform:pinchTransform];
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
    for (NSValue *aValue in points) {
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
