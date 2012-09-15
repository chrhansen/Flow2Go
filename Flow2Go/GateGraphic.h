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
- (BOOL)isContentsUnderPoint:(CGPoint)point;
- (NSArray *)getPathPoints;

- (void)panBeganAtPoint:(CGPoint)beginPoint;
- (void)panChangedToPoint:(CGPoint)nextPoint;
- (void)panEndedAtPoint:(CGPoint)endPoint;

@property (nonatomic, strong) UIBezierPath *path;
@property (nonatomic) CGRect bounds;
@property (nonatomic, strong) UIColor *strokeColor;
@property (nonatomic, strong) UIColor *fillColor;
@property (nonatomic) CGFloat strokeWidth;
@property (nonatomic) NSInteger gateTag;
@property (nonatomic) GateType gateType;

//@property (nonatomic) BOOL isDrawing;

@end
