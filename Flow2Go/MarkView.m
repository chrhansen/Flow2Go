//
//  MarkView.m
//  MarkTester
//
//  Created by Christian Hansen on 12/08/12.
//  Copyright (c) 2012 Christian Hansen. All rights reserved.
//

#import "MarkView.h"

@interface MarkView () <UIGestureRecognizerDelegate>

@property (nonatomic, strong) NSMutableArray *pathPoints;
@property (nonatomic, strong) UIBezierPath *path;
@property (nonatomic, strong) NSMutableArray *paths;
@property (nonatomic) CGPoint firstPoint;

@end

@implementation MarkView

#define REQUIRED_GAP 20.0
#define FIRSTPOINT_GAP 10.0

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self setupGestureRecognizers];
    [self drawPaths];
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
        
        for (NSUInteger i = 1; i < pathPoints.count; i++)
        {
            [self _extendPathWithPoint:[pathPoints[i] CGPointValue]];
        }
        [self _endPath];
    }
}


- (void)_updatePathWithPoint:(CGPoint)point
{
    if (self.pathPoints.count == 0)
    {
        [self _startPathAtPoint:point];
        [self.pathPoints addObject:[NSValue valueWithCGPoint:point]];
    }
    else if (self.pathPoints.count > 2)
    {
        CGFloat distance = [self _distanceFrom:self.firstPoint toPoint:point];
        if (distance < FIRSTPOINT_GAP)
        {
            [self.delegate didDrawPath:[self.path CGPath] withPoints:self.pathPoints insideRect:self.path.bounds sender:self];
            [self _endPath];
            [self _resetPath];
        }
        else
        {
            [self _extendPathWithPoint:point];
            [self.pathPoints addObject:[NSValue valueWithCGPoint:point]];
        }
    }
    else
    {
        [self _extendPathWithPoint:point];
        [self.pathPoints addObject:[NSValue valueWithCGPoint:point]];
    }
    
}


- (void)_startPathAtPoint:(CGPoint)startPoint
{
    [self _resetPath];
    self.firstPoint = startPoint;
    [self.paths addObject:self.path];
    [self.path moveToPoint:startPoint];
    [self setNeedsDisplay];
}


- (void)_extendPathWithPoint:(CGPoint)newPoint
{
    CGFloat distance = [self _distanceFrom:self.path.currentPoint toPoint:newPoint];
    if (distance > REQUIRED_GAP)
    {
        [self.path addLineToPoint:newPoint];
        [self setNeedsDisplayInRect:self.path.bounds];
    }
}

- (void)_endPath
{
    [self.path closePath];
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
- (void)singleTapAction:(UITapGestureRecognizer *)singleTapGesture;
{
    CGPoint point = [singleTapGesture locationInView:self];    
    switch (singleTapGesture.state)
    {
        case UIGestureRecognizerStateRecognized:
            [self _updatePathWithPoint:point];
            break;
            
        default:
            break;
    }
}

- (void)doubleTapAction:(UITapGestureRecognizer *)tapGesture
{
    NSInteger pathNo;
    CGPoint tapPoint = [tapGesture locationInView:self];
    switch (tapGesture.state)
    {
        case UIGestureRecognizerStateRecognized:
            pathNo = [self _indexOfPathForTapPoint:tapPoint];
            if (pathNo >= 0)
            {
                [self.delegate didDoubleTapPathNumber:pathNo];
                return;
            }
            else
            {
                [self.delegate didDoubleTapAtPoint:tapPoint];
            }
            break;
            
        default:
            break;
    }
}

- (void)setupGestureRecognizers
{
    UITapGestureRecognizer *doubleTapGestureRecognizer = [UITapGestureRecognizer.alloc initWithTarget:self
                                                                                               action:@selector(doubleTapAction:)];
    
    doubleTapGestureRecognizer.numberOfTapsRequired = 2;
    doubleTapGestureRecognizer.delegate = self;
    [self addGestureRecognizer:doubleTapGestureRecognizer];
    
    UITapGestureRecognizer *singleTapGestureRecognizer = [UITapGestureRecognizer.alloc initWithTarget:self
                                                                                               action:@selector(singleTapAction:)];
    
    singleTapGestureRecognizer.numberOfTapsRequired = 1;
    singleTapGestureRecognizer.delegate = self;
    [self addGestureRecognizer:singleTapGestureRecognizer];
    [singleTapGestureRecognizer requireGestureRecognizerToFail: doubleTapGestureRecognizer];
    [self addGestureRecognizer:singleTapGestureRecognizer];
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
