//
//  GateView.m
//  GatesLayout
//
//  Created by Christian Hansen on 13/09/12.
//  Copyright (c) 2012 Calcul8.it. All rights reserved.
//

#import "GateView.h"

@implementation GateView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}


- (void)setSelectedState
{
    self.backgroundColor = [UIColor colorWithWhite:0.2 alpha:0.2];
}


- (void)unSelect
{
    self.backgroundColor = UIColor.clearColor;;
}

- (BOOL)gateContainsPoint:(CGPoint)tapPoint
{
    // Overwrite the methods in subclasses
    return NO;
}


- (CGFloat)distanceFrom:(CGPoint)point1 toPoint:(CGPoint)point2
{
    CGFloat dX = point2.x - point1.x;
    CGFloat dY = point2.y - point1.y;
    return sqrtf(dX * dX + dY * dY);
}

- (void)panBegan:(CGPoint)firstPoint
{
    // Overwrite method in subclasses
}


- (void)panChanged:(CGPoint)newPoint
{
    // Overwrite method in subclasses
}

- (void)panEnded:(CGPoint)lastPoint
{
    // Overwrite method in subclasses
}


/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
