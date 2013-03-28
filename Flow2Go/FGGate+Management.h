//
//  FGGate+Management.h
//  Flow2Go
//
//  Created by Christian Hansen on 05/02/13.
//  Copyright (c) 2013 Christian Hansen. All rights reserved.
//

#import "FGGate.h"

// Gate Data dictionary keys
extern const NSString *GateType;
extern const NSString *GateName;
extern const NSString *XParName;
extern const NSString *YParName;
extern const NSString *GateXParNumber;
extern const NSString *GateYParNumber;
extern const NSString *Vertices;

@interface FGGate (Management)

+ (FGGate *)createChildGateInPlot:(FGNode *)parentNode type:(FGGateType)gateType vertices:(NSArray *)vertices;
+ (BOOL)is1DGateType:(FGGateType)gateType;
+ (BOOL)is2DGateType:(FGGateType)gateType;

- (NSDictionary *)gateData;
+ (NSArray *)gatesAsData:(NSArray *)gates;

+ (NSError *)deleteGate:(FGGate *)gate;
+ (NSError *)deleteGates:(NSArray *)gatesToDelete;

@end
