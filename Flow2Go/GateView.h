//
//  GateView.h
//  GatesLayout
//
//  Created by Christian Hansen on 13/09/12.
//  Copyright (c) 2012 Calcul8.it. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GateView : UIView

- (BOOL)gateContainsPoint:(CGPoint)tapPoint;
- (CGFloat)distanceFrom:(CGPoint)point1 toPoint:(CGPoint)point2;
- (void)setSelectedState;
- (void)unSelect;

- (void)panBegan:(CGPoint)firstPoint;
- (void)panChanged:(CGPoint)newPoint;
- (void)panEnded:(CGPoint)lastPoint;

@property (nonatomic, strong) NSString *indentifier;
@property (nonatomic) NSUInteger gateNumber;
@property (nonatomic) GateType gateType;
@property (nonatomic, strong) NSArray *vertices;

@end
