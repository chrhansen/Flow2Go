//
//  MarkView.m
//  MarkTester
//
//  Created by Christian Hansen on 12/08/12.
//  Copyright (c) 2012 Christian Hansen. All rights reserved.
//

#import "MarkView.h"

@interface MarkView () <UIGestureRecognizerDelegate>

- (void)panAction:(UIPanGestureRecognizer *)panGesture;

@property (nonatomic, strong) NSMutableArray *pathPoints;
@property (nonatomic, strong) UIBezierPath *path;

@end

@implementation MarkView

- (void)drawPathWithPoints:(NSArray *)pathPoints
{
    if (pathPoints.count > 2)
    {
        [self _startPathAtPoint:[pathPoints[0] CGPointValue]];
        
        for (NSUInteger i = 1; i < pathPoints.count - 1; i++)
        {
            [self _extendPathWithPoint:[pathPoints[i] CGPointValue]];
        }
        
        [self _endPathAtPoint:[pathPoints.lastObject CGPointValue]];
    }
    else
    {
        [self _resetPath];
    }
}

- (void)panAction:(UIPanGestureRecognizer *)panGesture
{
    CGPoint point = [panGesture locationInView:self];
    
    switch (panGesture.state)
    {
        case UIGestureRecognizerStateBegan:
            [self _startPathAtPoint:point];
            break;
            
        case UIGestureRecognizerStateChanged:
            [self _extendPathWithPoint:point];
            break;
            
        case UIGestureRecognizerStateEnded:
            [self _endPathAtPoint:point];
            break;
            
        default:
            break;
    }
}

- (void)_startPathAtPoint:(CGPoint)startPoint
{
    [self _resetPath];
    [self.path moveToPoint:startPoint];
    [self.pathPoints addObject:[NSValue valueWithCGPoint:startPoint]];
    [self setNeedsDisplay];
}

#define REQUIRED_GAP 20.0

- (void)_extendPathWithPoint:(CGPoint)newPoint
{
    CGFloat distance = [self _distanceFrom:self.path.currentPoint toPoint:newPoint];
    if (distance > REQUIRED_GAP)
    {
        [self.path addLineToPoint:newPoint];
        [self.pathPoints addObject:[NSValue valueWithCGPoint:newPoint]];
        [self setNeedsDisplayInRect:self.path.bounds];
    }
}

- (void)_endPathAtPoint:(CGPoint)endPoint
{
    [self.path closePath];
    [self.pathPoints addObject:[NSValue valueWithCGPoint:endPoint]];
    [self.delegate didDrawPath:[self.path CGPath] withPoints:self.pathPoints insideRect:self.path.bounds sender:self];
    [self setNeedsDisplayInRect:self.path.bounds];
}


- (void)_resetPath
{
    if (!self.path) {
        self.path = [UIBezierPath bezierPath];
        self.path.lineWidth = 2.0;
        self.path.lineCapStyle = kCGLineCapRound;
    }
    [self.path removeAllPoints];
    if (!self.pathPoints) {
        self.pathPoints = NSMutableArray.array;
    }
    [self.pathPoints removeAllObjects];
}


- (CGFloat)_distanceFrom:(CGPoint)point1 toPoint:(CGPoint)point2
{
    CGFloat dX = point2.x - point1.x;
    CGFloat dY = point2.y - point1.y;
    
    return sqrtf(dX * dX + dY * dY);
}


- (void)drawRect:(CGRect)rect
{
    //CGContextRef context = UIGraphicsGetCurrentContext();
    [UIColor.redColor setStroke];
    [UIColor.redColor setFill];
    [self.path fillWithBlendMode:kCGBlendModeNormal alpha:0.3];

   // [self.path fill];
    [self.path stroke];
}

@end
