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
- (void)gatesContainerView:(GatesContainerView *)gatesContainerView didTapInfoButtonForGate:(NSUInteger)gateNo inRect:(CGRect)rect;
- (void)gatesContainerView:(GatesContainerView *)gatesContainerView didModifyGateNo:(NSUInteger)gateNo gateType:(GateType)gateType vertices:(NSArray *)updatedVertices;

@end

@interface GatesContainerView : UIView <UIGestureRecognizerDelegate>

- (void)redrawGates;
- (void)insertNewGate:(GateType)gateType gateTag:(NSInteger)tagNumber;

@property (nonatomic, weak) id<GatesContainerViewDelegate> delegate;

@end
