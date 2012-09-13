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
@property (nonatomic, strong) NSMutableArray *polygonPathPoints;
@property (nonatomic, strong) UIColor *selectedColor;

@end

@implementation PolygonGateView

#define REQUIRED_GAP 30.0

- (void)baseInit
{
    self.backgroundColor = UIColor.clearColor;
    self.polygonPathPoints = NSMutableArray.array;
    self.polygonPath = [UIBezierPath bezierPath];
    self.polygonPath.lineWidth = 2.0;
    self.polygonPath.lineCapStyle = kCGLineCapRound;
    self.gateType = kGateTypePolygon;
}


- (PolygonGateView *)initWithFrame:(CGRect)frame polygonGateVertices:(NSArray *)vertices;
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [self baseInit];
        if (vertices)
        {
            [self _drawPolygonPathWithPoints:vertices];
            self.vertices = vertices;
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
}


- (void)panChanged:(CGPoint)newPoint
{
    [self _extendPolygonPathWithPoint:newPoint];
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
    CGFloat distance = [self distanceFrom:self.polygonPath.currentPoint toPoint:newPoint];
    if (distance > REQUIRED_GAP)
    {
        [self.polygonPath addLineToPoint:newPoint];
        [self.polygonPathPoints addObject:[NSValue valueWithCGPoint:newPoint]];
        
        [self setNeedsDisplay];
    }
}


- (void)_endPath
{
    [self.polygonPath closePath];
    [self setNeedsDisplay];
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


@end
