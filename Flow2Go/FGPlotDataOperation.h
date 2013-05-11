//
//  FGPlotDataOperation.h
//  Flow2Go
//
//  Created by Christian Hansen on 01/04/13.
//  Copyright (c) 2013 Christian Hansen. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FGFCSFile;
@class FGPlotDataCalculator;
@class FGPlotDataOperation;
@class FGGateCalculator;

@interface FGPlotDataOperation : NSOperation

- (id)initWithFCSFile:(FGFCSFile *)fcsFile
          parentGates:(NSArray *)gatesData
          plotOptions:(NSDictionary *)plotOptions
               subset:(NSUInteger *)subset
          subsetCount:(NSUInteger)subsetCount;

- (void)setCompletionBlock:(void (^)(NSError *error, FGGateCalculator *gateData, FGPlotDataCalculator *plotData))completion;

@property (nonatomic, readonly, getter = hasCalculatedSubet) BOOL calculatedSubset;

@end
