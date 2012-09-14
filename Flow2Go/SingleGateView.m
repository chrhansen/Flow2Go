//
//  SingleGateView.m
//  Shapes
//
//  Created by Christian Hansen on 13/09/12.
//  Copyright (c) 2012 Calcul8.it. All rights reserved.
//

#import "SingleGateView.h"
#import <QuartzCore/QuartzCore.h>

@interface SingleGateView ()

@property (nonatomic) CGFloat leftLocation;
@property (nonatomic) CGFloat rightLocation;
@property (nonatomic, strong) UIBezierPath *leftLine;
@property (nonatomic, strong) UIBezierPath *rightLine;


@end

@implementation SingleGateView



#define GATE_HEIGHT 30
#define DEFAULT_LINE_WIDTH 2

- (SingleGateView *)initWithLeftEdge:(CGFloat)leftEdge rightEdge:(CGFloat)rightEdge y:(CGFloat)yCenter gateTag:(NSInteger)tagNumber;
{
    CGRect frame = CGRectMake(leftEdge, yCenter - 0.5f * GATE_HEIGHT, rightEdge - leftEdge, GATE_HEIGHT);
    
    if ((self = [super initWithFrame:frame]))
    {
        self.backgroundColor = UIColor.clearColor;
        self.lineColor = UIColor.redColor;
        self.lineWidth = DEFAULT_LINE_WIDTH;
        self.gateTag = tagNumber;
        self.gateType = kGateTypeSingleRange;
        self.layer.masksToBounds = NO;
        [self updateLeftLocation];
        [self updateRightLocation];
    }
    return self;
}


- (BOOL)gateContainsPoint:(CGPoint)tapPoint
{
    return CGRectContainsPoint(self.bounds, tapPoint);
}

- (void)updateWithPinch:(CGFloat)pinchScale
{
    CGRect frame = self.frame;
    CGPoint center = self.center;
    frame.size.width *= pinchScale;
    self.frame = frame;
    self.center = center;
    [self updateLeftLocation];
    [self updateRightLocation];
}


- (void)updateLeftLocation
{
    CGFloat halfWidth = DEFAULT_LINE_WIDTH * 0.5f;
    CGPoint startPoint = CGPointMake(self.bounds.origin.x+halfWidth, self.bounds.origin.y);
    CGPoint endPoint = CGPointMake(self.bounds.origin.x+halfWidth, self.bounds.size.height);
    
    [self.leftLine removeAllPoints];
    [self.leftLine moveToPoint:startPoint];
    [self.leftLine addLineToPoint:endPoint];
    [self setNeedsDisplay];
}


- (void)updateRightLocation
{
    CGFloat halfWidth = DEFAULT_LINE_WIDTH * 0.5f;
    CGPoint startPoint = CGPointMake(self.bounds.size.width-halfWidth, self.bounds.origin.y);
    CGPoint endPoint = CGPointMake(self.bounds.size.width-halfWidth, self.bounds.size.height);
    
    [self.rightLine removeAllPoints];
    [self.rightLine moveToPoint:startPoint];
    [self.rightLine addLineToPoint:endPoint];
    [self setNeedsDisplay];
}

- (void)setLineWidth:(CGFloat)lineWidth
{
    if (_lineWidth != lineWidth)
    {
        _lineWidth = lineWidth;
        self.leftLine.lineWidth = lineWidth;
        self.rightLine.lineWidth = lineWidth;
    }
}


- (UIBezierPath *)leftLine
{
    if (_leftLine == nil)
    {
        _leftLine = [UIBezierPath bezierPath];

    }
    return _leftLine;
}


- (UIBezierPath *)rightLine
{
    if (_rightLine == nil)
    {
        _rightLine = [UIBezierPath bezierPath];
    }
    return _rightLine;
}


- (void)drawRect:(CGRect)rect
{
    [self.lineColor setStroke];
    [self.leftLine strokeWithBlendMode:kCGBlendModeNormal alpha:0.8];
    [self.rightLine strokeWithBlendMode:kCGBlendModeNormal alpha:0.8];
}


@end
