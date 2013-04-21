//
//  GatesContainerViewNew.h
//  Flow2Go
//
//  Created by Christian Hansen on 15/09/12.
//  Copyright (c) 2012 Christian Hansen. All rights reserved.
//

#import <UIKit/UIKit.h>
@class FGGatesContainerView;

@protocol GatesContainerViewDelegate <NSObject>
// Datasource methods
- (NSUInteger)numberOfGatesInGatesContainerView:(FGGatesContainerView *)gatesContainerView;
- (FGGateType)gatesContainerView:(FGGatesContainerView *)gatesContainerView gateTypeForGateNo:(NSUInteger)gateNo;
- (NSArray *)gatesContainerView:(FGGatesContainerView *)gatesContainerView verticesForGate:(NSUInteger)gateNo;

// Delegate methods
- (void)gatesContainerView:(FGGatesContainerView *)gatesContainerView didTapGate:(NSUInteger)gateNo inRect:(CGRect)rect;
- (void)gatesContainerView:(FGGatesContainerView *)gatesContainerView didModifyGateNo:(NSUInteger)gateNo gateType:(FGGateType)gateType vertices:(NSArray *)updatedVertices; //Sent on first touch down (vertices set to nil) and after touch release (containing modified gate vertices - in view coordinates)
- (void)gatesContainerView:(FGGatesContainerView *)gatesContainerView didDoubleTapGate:(NSUInteger)gateNo;

@end

@interface FGGatesContainerView : UIView <UIGestureRecognizerDelegate>

- (void)redrawGates;
- (void)removeGateViews;
- (void)setHidden:(BOOL)hidden animated:(BOOL)animated;
- (void)insertNewGate:(FGGateType)gateType gateTag:(NSInteger)tagNumber;

@property (nonatomic, weak) id<GatesContainerViewDelegate> delegate;

@end
