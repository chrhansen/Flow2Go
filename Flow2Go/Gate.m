//
//  Gate.m
//  Flow2Go
//
//  Created by Christian Hansen on 21/08/12.
//  Copyright (c) 2012 Christian Hansen. All rights reserved.
//

#import "Gate.h"


@implementation Gate

@dynamic cellCount;
@dynamic name;
@dynamic type;
@dynamic vertices;

+ (Gate *)createChildGateInPlot:(Node *)parentNode
                           type:(GateType)gateType
                       vertices:(NSArray *)vertices
{
    Gate *newGate = [Gate createInContext:parentNode.managedObjectContext];
    
    newGate.type = [NSNumber numberWithInteger:gateType];
    newGate.vertices = vertices;
    newGate.parentNode = parentNode;
    
    newGate.xParName = parentNode.xParName;
    newGate.yParName = parentNode.yParName;
    
    return newGate;
}

@end
