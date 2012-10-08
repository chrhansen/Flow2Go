//
//  Graphic.h
//  ShapeTest
//
//  Created by Christian Hansen on 15/09/12.
//  Copyright (c) 2012 Calcul8.it. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GateGraphic : NSObject

- (GateGraphic *)initWithVertices:(NSArray *)vertices;
- (GateGraphic *)initWithBoundsOfContainerView:(CGRect)bounds;

- (void)showDragableHooks;
- (void)hideDragableHooks;

- (BOOL)isContentsUnderPoint:(CGPoint)point;
- (NSArray *)getPathPoints;

- (void)panBeganAtPoint:(CGPoint)beginPoint;
- (void)panChangedToPoint:(CGPoint)nextPoint;
- (void)panEndedAtPoint:(CGPoint)endPoint;
- (void)pinchBeganAtLocation:(CGPoint)location withScale:(CGFloat)scale;
- (void)pinchChangedAtLocation:(CGPoint)location withScale:(CGFloat)scale;
- (void)pinchEndedAtLocation:(CGPoint)location withScale:(CGFloat)scale;

@property (nonatomic, strong) UIBezierPath *path;
@property (nonatomic) CGRect bounds;
@property (nonatomic, strong) UIColor *strokeColor;
@property (nonatomic, strong) UIColor *fillColor;
@property (nonatomic, strong) UIColor *hookColor;
@property (nonatomic) CGFloat strokeWidth;
@property (nonatomic) NSInteger gateTag;
@property (nonatomic) GateType gateType;
@property (nonatomic, strong) NSMutableArray *hooks;

//@property (nonatomic) BOOL isDrawing;

@end
