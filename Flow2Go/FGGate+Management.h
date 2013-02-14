//
//  FGGate+Management.h
//  Flow2Go
//
//  Created by Christian Hansen on 05/02/13.
//  Copyright (c) 2013 Christian Hansen. All rights reserved.
//

#import "FGGate.h"

@interface FGGate (Management)

+ (FGGate *)createChildGateInPlot:(FGNode *)parentNode type:(FGGateType)gateType vertices:(NSArray *)vertices;
+ (BOOL)is1DGateType:(FGGateType)gateType;
+ (BOOL)is2DGateType:(FGGateType)gateType;

@end
