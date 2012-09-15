//
//  PolygonGateView.m
//  GatesLayout
//
//  Created by Christian Hansen on 13/09/12.
//  Copyright (c) 2012 Calcul8.it. All rights reserved.
//

#import "PolygonGateView.h"

@interface PolygonGateView ()

@property (nonatomic, strong) UIBezierPath *polygonPath;
@property (nonatomic, strong) UIColor *selectedColor;

@end

@implementation PolygonGateView

#define REQUIRED_GAP 30.0

- (void)baseInit
{
    self.backgroundColor = UIColor.clearColor;
    self.polygonPath = [UIBezierPath bezierPath];
    self.polygonPath.lineWidth = 2.0;
    self.polygonPath.lineCapStyle = kCGLineCapRound;
    self.gateType = kGateTypePolygon;
}


- (PolygonGateView *)initWithFrame:(CGRect)frame polygonGateVertices:(NSArray *)vertices gateTag:(NSInteger)tagNumber
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [self baseInit];
        self.gateTag = tagNumber;
        if (vertices)
        {
            [self _drawPolygonPathWithPoints:vertices];
            self.vertices = [vertices mutableCopy];
        }
        else
        {
            self.vertices = NSMutableArray.array;
        }
    }
    return self;
}


- (BOOL)gateContainsPoint:(CGPoint)tapPoint
{
    return [self.polygonPath containsPoint:tapPoint];
}


- (void)setSelectedState
{
    self.selectedColor = UIColor.grayColor;
    [self setNeedsDisplay];
}


- (void)unSelect
{
    self.selectedColor = nil;
    [self setNeedsDisplay];
}


- (void)panBegan:(CGPoint)firstPoint
{
    [self _startPolygonPathAtPoint:firstPoint];
    [self.vertices addObject:[NSValue valueWithCGPoint:firstPoint]];
}


- (void)panChanged:(CGPoint)newPoint
{
    CGFloat distance = [self distanceFrom:self.polygonPath.currentPoint toPoint:newPoint];
    if (distance > REQUIRED_GAP)
    {
        [self _extendPolygonPathWithPoint:newPoint];
        [self.vertices addObject:[NSValue valueWithCGPoint:newPoint]];
    }
    
}


- (void)panEnded:(CGPoint)lastPoint
{
    [self _endPath];
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


- (void)_startPolygonPathAtPoint:(CGPoint)startPoint
{
    [self.polygonPath moveToPoint:startPoint];
    [self setNeedsDisplay];
}


- (void)_extendPolygonPathWithPoint:(CGPoint)newPoint
{
    [self.polygonPath addLineToPoint:newPoint];
    [self setNeedsDisplay];
}


- (void)_endPath
{
    [self.polygonPath closePath];
    [self setNeedsDisplay];
    [self getPathPoints:self.polygonPath];
    NSLog(@"Recorded points: %@", self.vertices);
}


- (void)drawRect:(CGRect)rect
{
    [UIColor.redColor setStroke];
    if (self.selectedColor)
    {
        [self.selectedColor setFill];
    }
    else
    {
        [UIColor.redColor setFill];
    }
    
    [self.polygonPath fillWithBlendMode:kCGBlendModeNormal alpha:0.3];
    [self.polygonPath stroke];
}


- (void)getPathPoints:(UIBezierPath *)yourPath
{
    NSMutableArray *bezierPoints = [NSMutableArray array];
    CGPathApply(yourPath.CGPath, (__bridge void *)(bezierPoints), ChristianCGPathApplierFunc);
    NSLog(@"Points from BezierPath: %@", bezierPoints);
}


void ChristianCGPathApplierFunc (void *info, const CGPathElement *element) {
    NSMutableArray *bezierPoints = (__bridge NSMutableArray *)info;
    
    CGPoint *points = element->points;
    CGPathElementType type = element->type;
    
    switch(type) {
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