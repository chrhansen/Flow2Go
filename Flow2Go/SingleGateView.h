//
//  SingleGateView.h
//  Shapes
//
//  Created by Christian Hansen on 13/09/12.
//  Copyright (c) 2012 Calcul8.it. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GateView.h"

@interface SingleGateView : GateView

- (SingleGateView *)initWithLeftEdge:(CGFloat)leftEdge rightEdge:(CGFloat)rightEdge y:(CGFloat)yCenter gateTag:(NSInteger)tagNumber;

- (void)updateWithPinch:(CGFloat)pinchScale;


@property (nonatomic) CGFloat lineWidth;
@property (nonatomic, strong) UIColor *lineColor;

@end
