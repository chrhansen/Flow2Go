//
//  GatesContainerViewNew.h
//  Flow2Go
//
//  Created by Christian Hansen on 15/09/12.
//  Copyright (c) 2012 Christian Hansen. All rights reserved.
//

#import <UIKit/UIKit.h>
@class GatesContainerView;

@protocol GatesContainerViewDelegate <NSObject>
// Datasource methods
- (NSUInteger)numberOfGatesInGatesContainerView:(GatesContainerView *)gatesContainerView;
- (GateType)gatesContainerView:(GatesContainerView *)gatesContainerView gateTypeForGateNo:(NSUInteger)gateNo;
- (NSArray *)gatesContainerView:(GatesContainerView *)gatesContainerView verticesForGate:(NSUInteger)gateNo;

// Delegate methods
- (void)gatesContainerView:(GatesContainerView *)gatesContainerView didTapGate:(NSUInteger)gateNo inRect:(CGRect)rect;
- (void)gatesContainerView:(GatesContainerView *)gatesContainerView didModifyGateNo:(NSUInteger)gateNo gateType:(GateType)gateType vertices:(NSArray *)updatedVertices;
- (void)gatesContainerView:(GatesContainerView *)gatesContainerView didDoubleTapGate:(NSUInteger)gateNo;

@end

@interface GatesContainerView : UIView <UIGestureRecognizerDelegate>

- (void)redrawGates;
- (void)removeGateViews;
- (void)insertNewGate:(GateType)gateType gateTag:(NSInteger)tagNumber;

@property (nonatomic, weak) id<GatesContainerViewDelegate> delegate;

@end
