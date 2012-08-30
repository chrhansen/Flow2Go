//
//  Gate.h
//  Flow2Go
//
//  Created by Christian Hansen on 21/08/12.
//  Copyright (c) 2012 Christian Hansen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "Node.h"


@interface Gate : Node

+ (Gate *)createChildGateInPlot:(Node *)parentNode
                           type:(GateType)gateType
                       vertices:(NSArray *)vertices;


@property (nonatomic, retain) NSNumber * cellCount;
@property (nonatomic, retain) NSNumber * type;
@property (nonatomic, retain) NSArray *vertices;
@property (nonatomic, retain) NSData *subSet;

@end
