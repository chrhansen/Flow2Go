//
//  MarkView.m
//  MarkTester
//
//  Created by Christian Hansen on 12/08/12.
//  Copyright (c) 2012 Christian Hansen. All rights reserved.
//

#import "MarkView.h"

@interface MarkView () <UIGestureRecognizerDelegate>

- (IBAction)panAction:(UIPanGestureRecognizer *)panGesture;
- (IBAction)doubleTapAction:(UITapGestureRecognizer *)tapGesture;

@property (nonatomic, strong) NSMutableArray *pathPoints;
@property (nonatomic, strong) UIBezierPath *path;
@property (nonatomic, strong) NSMutableArray *paths;

@end

@implementation MarkView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self drawPaths];
    }
    return self;
}

- (void)drawPaths
{
    NSUInteger numberOfPaths = [self.delegate numberOfPathsInMarkView:self];
    for (NSUInteger pathNo = 0; pathNo < numberOfPaths; pathNo++)
    {
        [self _drawPathWithPoints:[self.delegate verticesForPath:pathNo inView:self]];
    }
}


- (void)_drawPathWithPoints:(NSArray *)pathPoints
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
}


- (void)_startPathAtPoint:(CGPoint)startPoint
{
    [self _resetPath];
    [self.paths addObject:self.path];
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
    [self.paths replaceObjectAtIndex:self.paths.count - 1
                          withObject:[self.path copy]];

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
    if (!self.paths) {
        self.paths = NSMutableArray.array;
    }
}


- (CGFloat)_distanceFrom:(CGPoint)point1 toPoint:(CGPoint)point2
{
    CGFloat dX = point2.x - point1.x;
    CGFloat dY = point2.y - point1.y;
    
    return sqrtf(dX * dX + dY * dY);
}


- (void)drawRect:(CGRect)rect
{
    [UIColor.redColor setStroke];
    [UIColor.redColor setFill];

    for (UIBezierPath *aPath in self.paths)
    {
        [aPath fillWithBlendMode:kCGBlendModeNormal alpha:0.3];
        [aPath stroke];
    }
}


#pragma mark Gesture Recognizers
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
            [self.delegate didDrawPath:[self.path CGPath] withPoints:self.pathPoints insideRect:self.path.bounds sender:self];
            break;
            
        default:
            break;
    }
}

- (void)doubleTapAction:(UITapGestureRecognizer *)tapGesture
{
    NSInteger pathNo;
    switch (tapGesture.state)
    {
        case UIGestureRecognizerStateRecognized:
            pathNo = [self _indexOfPathForTapPoint:[tapGesture locationInView:self]];
            if (pathNo >= 0)
            {
                [self.delegate didDoubleTapPathNumber:pathNo];
            }
            break;
            
            
        default:
            break;
    }
}

- (NSInteger)_indexOfPathForTapPoint:(CGPoint)tapPoint
{
    for (UIBezierPath *aPath in self.paths)
    {
        if (CGPathContainsPoint([aPath CGPath], NULL, tapPoint, TRUE))
        {
            return [self.paths indexOfObject:aPath];
        }
    }
    return -1;
}

@end
