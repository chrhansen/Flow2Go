//
//  Gate.h
//  Flow2Go
//
//  Created by Christian Hansen on 14/08/12.
//  Copyright (c) 2012 Christian Hansen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FGGraphPoint.h"

@class FGFCSFile;

@interface FGGateCalculator : NSObject

+ (FGGateCalculator *)eventsInsideGatesWithDatas:(NSArray *)gateDatas fcsFile:(FGFCSFile *)fcsFile;
+ (FGGateCalculator *)eventsInsideGateWithData:(NSDictionary *)gateData fcsFile:(FGFCSFile *)fcsFile subSet:(NSUInteger *)subSet subSetCount:(NSUInteger)subSetCount;

@property (nonatomic) NSUInteger *eventsInside;
@property (nonatomic) NSUInteger countOfEventsInside;

@end
