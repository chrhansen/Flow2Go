//
//  GatesContainerView.h
//  Shapes
//
//  Created by Christian Hansen on 13/09/12.
//  Copyright (c) 2012 Calcul8.it. All rights reserved.
//

#import <UIKit/UIKit.h>
@class GatesContainerView;

@protocol GatesContainerViewDelegate <NSObject>
// Datasource methods
- (NSUInteger)numberOfGatesInGatesContainerView:(GatesContainerView *)gatesContainerView;
- (GateType)gatesContainerView:(GatesContainerView *)gatesContainerView gateTypeForGateNo:(NSUInteger)gateNo;
- (NSArray *)gatesContainerView:(GatesContainerView *)gatesContainerView verticesForGate:(NSUInteger)gateNo;

// Delegate methods
- (void)gatesContainerView:(GatesContainerView *)gatesContainerView didDrawGate:(GateType)gateType withPoints:(NSArray *)pathPoints infoButton:(UIButton *)infoButton;
- (void)gatesContainerView:(GatesContainerView *)gatesContainerView didTapInfoButtonForPath:(UIButton *)buttonWithTagNumber;
- (void)gatesContainerView:(GatesContainerView *)gatesContainerView didChangeViewForGateNo:(NSUInteger)gateNo gateType:(NSInteger)gateType vertices:(NSArray *)vertices;

@end

@interface GatesContainerView : UIView <UIGestureRecognizerDelegate>

- (void)redrawGates;
- (void)insertNewGate:(GateType)gateType vertices:(NSArray *)vertices;

@property (nonatomic, weak) id<GatesContainerViewDelegate> delegate;

@end
