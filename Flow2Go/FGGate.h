//
//  FGGate.h
//  Flow2Go
//
//  Created by Christian Hansen on 05/02/13.
//  Copyright (c) 2013 Christian Hansen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "FGNode.h"

@class FGAnalysis;

@interface FGGate : FGNode

+ (FGGate *)createChildGateInPlot:(FGNode *)parentNode type:(FGGateType)gateType vertices:(NSArray *)vertices;

+ (BOOL)is1DGateType:(FGGateType)gateType;
+ (BOOL)is2DGateType:(FGGateType)gateType;

@property (nonatomic, retain) NSNumber * cellCount;
@property (nonatomic, retain) NSData * subSet;
@property (nonatomic, retain) NSNumber * type;
@property (nonatomic, retain) id vertices;
@property (nonatomic, retain) FGAnalysis *analysis;

@end
