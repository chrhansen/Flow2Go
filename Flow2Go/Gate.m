//
//  Gate.m
//  Flow2Go
//
//  Created by Christian Hansen on 21/08/12.
//  Copyright (c) 2012 Christian Hansen. All rights reserved.
//

#import "Gate.h"
#import "Analysis.h"

@implementation Gate

@dynamic cellCount;
@dynamic type;
@dynamic vertices;
@dynamic subSet;

+ (Gate *)createChildGateInPlot:(Node *)parentNode
                           type:(GateType)gateType
                       vertices:(NSArray *)vertices
{
    Gate *newGate = [Gate createInContext:parentNode.managedObjectContext];
    
    newGate.type = [NSNumber numberWithInteger:gateType];
    newGate.vertices = vertices;
    newGate.parentNode = parentNode;
    
    newGate.analysis = parentNode.analysis;
    newGate.xParName = parentNode.xParName;
    newGate.yParName = parentNode.yParName;
    newGate.xParNumber = parentNode.xParNumber;
    newGate.yParNumber = parentNode.yParNumber;
    
    newGate.name = [newGate defaultGateName];
    
    return newGate;
}


- (NSString *)defaultGateName
{
    return [NSString stringWithFormat:@"#%i: %@, %@", self.analysis.gates.count, self.xParName, self.yParName];
}

@end
