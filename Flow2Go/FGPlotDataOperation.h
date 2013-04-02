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

@protocol FGPlotDataOperationDelegate <NSObject>

- (void)plotDataOperationDidFinish:(FGPlotDataOperation *)plotDataOperation;

@end


@interface FGPlotDataOperation : NSOperation

- (id)initWithFCSFile:(FGFCSFile *)fcsFile
          parentGates:(NSArray *)gatesData
          plotOptions:(NSDictionary *)plotOptions
               subset:(NSUInteger *)subset
          subsetCount:(NSUInteger)subsetCount;

@property (nonatomic, strong) FGPlotDataCalculator *plotDataCalculator;
@property (nonatomic, strong) FGGateCalculator *gateCalculator;
@property (nonatomic, readonly, getter = hasCalculatedSubet) BOOL calculatedSubset;
@property (nonatomic, weak) id<FGPlotDataOperationDelegate> delegate;

@end
