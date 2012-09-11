//
//  MarkView.m
//  MarkTester
//
//  Created by Christian Hansen on 12/08/12.
//  Copyright (c) 2012 Christian Hansen. All rights reserved.
//

#import "MarkView.h"

@interface MarkView () <UIGestureRecognizerDelegate>

@property (nonatomic, strong) NSMutableArray *polygonPathPoints;
@property (nonatomic, strong) UIBezierPath *polygonPath;
@property (nonatomic, strong) NSMutableArray *polygonPaths;
@property (nonatomic, strong) NSMutableArray *polygonDots;
@property (nonatomic) GateType currentGateState;

@property (nonatomic) CGPoint firstPoint;

@end

@implementation MarkView

#define REQUIRED_GAP 30.0

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self setupGestureRecognizers];
}

- (void)reloadPaths
{
    [self.polygonPaths removeAllObjects];
    [self _resetCurrentPolygonPath];
    [self _removeInfoButtons];
    [self setNeedsDisplay];
    NSUInteger numberOfPaths = [self.delegate numberOfPathsInMarkView:self];
    for (NSUInteger pathNo = 0; pathNo < numberOfPaths; pathNo++)
    {
        NSArray *vertices = [self.delegate verticesForPath:pathNo inView:self];
        [self _drawPolygonPathWithPoints:vertices];
        [self _addInfoButtonToPath:pathNo atPoint:[vertices[0] CGPointValue]];
    }
}


- (void)setReadyForGateOfType:(GateType)gateType
{
    self.currentGateState = gateType;
}

- (void)_removeInfoButtons
{
    for (UIView *aView in self.subviews)
    {
        if ([aView isKindOfClass:UIButton.class])
        {
            UIButton *button = (UIButton *)aView;
            if (button.buttonType == UIButtonTypeInfoLight)
            {
                [aView removeFromSuperview];
            }
        }
    }
}


- (UIButton *)_addInfoButtonToPath:(NSInteger)pathNo atPoint:(CGPoint)location
{
    UIButton* infoButton = [UIButton buttonWithType:UIButtonTypeInfoLight];
    [infoButton setCenter:location];
    [self addSubview:infoButton];
    infoButton.tag = pathNo;
    [infoButton addTarget:self action:@selector(infoButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    return infoButton;
}


- (void)infoButtonTapped:(UIButton *)sender
{
    [self.delegate markView:self didTapInfoButtonForPath:sender];
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
    [self _resetCurrentPolygonPath];
    self.firstPoint = startPoint;
    [self.polygonPaths addObject:self.polygonPath];
    //[self addDotAtPoint:startPoint];
    [self.polygonPath moveToPoint:startPoint];
    [self setNeedsDisplay];
}


- (void)_extendPolygonPathWithPoint:(CGPoint)newPoint
{
    CGFloat distance = [self _distanceFrom:self.polygonPath.currentPoint toPoint:newPoint];
    if (distance > REQUIRED_GAP)
    {
        [self.polygonPath addLineToPoint:newPoint];
        //[self addDotAtPoint:newPoint];
        [self.polygonPathPoints addObject:[NSValue valueWithCGPoint:newPoint]];

        [self setNeedsDisplay];
    }
}

- (void)_endPath
{
    [self.polygonPath closePath];
    [self.polygonPaths replaceObjectAtIndex:self.polygonPaths.count - 1 withObject:[self.polygonPath copy]];
    [self setNeedsDisplay];
}

#define DOT_SIZE 15.0

- (void)setPolygonDots:(NSMutableArray *)polygonDots
{
    _polygonDots = polygonDots;
}


- (void)addDotAtPoint:(CGPoint)point
{
    UIBezierPath *dot = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(point.x - DOT_SIZE / 2.0, point.y - DOT_SIZE / 2.0, DOT_SIZE, DOT_SIZE)];
    if (!self.polygonDots)
    {
        self.polygonDots = NSMutableArray.array;
    }
    [self.polygonDots addObject:dot];
    [self setNeedsDisplay];
}


- (void)_resetCurrentPolygonPath
{
    if (!self.polygonPath) {
        self.polygonPath = [UIBezierPath bezierPath];
        self.polygonPath.lineWidth = 2.0;
        self.polygonPath.lineCapStyle = kCGLineCapRound;
    }
    [self.polygonPath removeAllPoints];
    if (!self.polygonPathPoints) {
        self.polygonPathPoints = NSMutableArray.array;
    }
    
    [self.polygonPathPoints removeAllObjects];
    if (!self.polygonPaths) {
        self.polygonPaths = NSMutableArray.array;
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

    for (UIBezierPath *aPath in self.polygonPaths)
    {
        [aPath fillWithBlendMode:kCGBlendModeNormal alpha:0.3];
        [aPath stroke];
    }
    for (UIBezierPath *aDot in self.polygonDots)
    {
        [aDot fillWithBlendMode:kCGBlendModeNormal alpha:0.5];
        [aDot stroke];
    }
}


#pragma mark Gesture Recognizers
- (void)panAction:(UIPanGestureRecognizer *)panGesture;
{
    switch (self.currentGateState)
    {
        case kGateTypePolygon:
            [self _updatePolygonPathWithPanGesture:panGesture];
            break;
        
        case kGateTypeSingleRange:
            [self _updateSingleRangePathWithPanGesture:panGesture];
            break;
            

        default:
            break;
    }
}


- (void)_updatePolygonPathWithPanGesture:(UIPanGestureRecognizer *)panGesture
{
    CGPoint point = [panGesture locationInView:self];
    switch (panGesture.state)
    {
        case UIGestureRecognizerStateBegan:
            [self _startPolygonPathAtPoint:point];
            [self.polygonPathPoints addObject:[NSValue valueWithCGPoint:point]];
            break;
            
        case UIGestureRecognizerStateChanged:
            [self _extendPolygonPathWithPoint:point];
            break;
            
        case UIGestureRecognizerStateEnded:
            [self.delegate markView:self didDrawGate:kGateTypePolygon withPoints:self.polygonPathPoints infoButton:[self _addInfoButtonToPath:self.polygonPaths.count - 1 atPoint:[self.polygonPathPoints[0] CGPointValue]]];
            
            [self _endPath];
            [self _resetCurrentPolygonPath];
            
            break;
            
        default:
            break;
    }
}


- (void)_updateSingleRangePathWithPanGesture:(UIPanGestureRecognizer *)panGesture
{
    
}


- (void)longPressAction:(UILongPressGestureRecognizer *)longPressGesture
{
    NSInteger dotNo;
    //UIBezierPath *pressedDot = nil;
    CGPoint pressPoint = [longPressGesture locationInView:self];
    switch (longPressGesture.state)
    {
        case UIGestureRecognizerStateBegan:
            dotNo = [self _indexOfDotForPoint:pressPoint];
            if (dotNo >= 0)
            {
                //pressedDot = self.dots[dotNo];
                UIBezierPath *dot = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(pressPoint.x - 3.0 * DOT_SIZE / 2.0, pressPoint.y - 3.0 * DOT_SIZE / 2.0, 3.0 * DOT_SIZE, 3.0 * DOT_SIZE)];
                [self.polygonDots replaceObjectAtIndex:dotNo withObject:dot];
                [self setNeedsDisplay];
                return;
            }
            break;
            
        case UIGestureRecognizerStateChanged | UIGestureRecognizerStateEnded:
            dotNo = [self _indexOfDotForPoint:pressPoint];
            if (dotNo >= 0)
            {
                UIBezierPath *dot = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(pressPoint.x - DOT_SIZE / 2.0, pressPoint.y - DOT_SIZE / 2.0, DOT_SIZE, DOT_SIZE)];
                [self.polygonDots replaceObjectAtIndex:dotNo withObject:dot];
                [self setNeedsDisplay];
                return;
            }
            break;
            
        default:
            break;
    }
}

- (void)setupGestureRecognizers
{
    UIPanGestureRecognizer *panGestureRecognizer = [UIPanGestureRecognizer.alloc initWithTarget:self
                                                                                         action:@selector(panAction:)];
    panGestureRecognizer.delegate = self;
    [self addGestureRecognizer:panGestureRecognizer];
    
    UILongPressGestureRecognizer *longPressGestureRecognizer = [UILongPressGestureRecognizer.alloc initWithTarget:self
                                                                                                           action:@selector(longPressAction:)];
    
    longPressGestureRecognizer.delegate = self;
    
    [self addGestureRecognizer:longPressGestureRecognizer];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}


- (NSInteger)_indexOfDotForPoint:(CGPoint)point
{
    for (UIBezierPath *aPath in self.polygonDots)
    {
        if (CGPathContainsPoint([aPath CGPath], NULL, point, TRUE))
        {
            return [self.polygonDots indexOfObject:aPath];
        }
    }
    return -1;
}


@end
