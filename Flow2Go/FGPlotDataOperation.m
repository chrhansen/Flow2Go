//
//  FGPlotDataOperation.m
//  Flow2Go
//
//  Created by Christian Hansen on 01/04/13.
//  Copyright (c) 2013 Christian Hansen. All rights reserved.
//

#import "FGPlotDataOperation.h"
#import "FGFCSFile.h"
#import "FGPlotDataCalculator.h"
#import "FGGateCalculator.h"

@interface FGPlotDataOperation ()

@property (nonatomic, strong) FGFCSFile *fcsFile;
@property (nonatomic, strong) NSDictionary *plotOptions;
@property (nonatomic, strong) NSArray *parentGates;
@property (nonatomic) NSUInteger *subset;
@property (nonatomic) NSUInteger subsetCount;
@property (nonatomic) BOOL subsetCalculated;
@end


@implementation FGPlotDataOperation

- (id)initWithFCSFile:(FGFCSFile *)fcsFile
          parentGates:(NSArray *)gatesData
          plotOptions:(NSDictionary *)plotOptions
               subset:(NSUInteger *)subset
          subsetCount:(NSUInteger)subsetCount
{
    self = [super init];
    if (self) {
        self.fcsFile          = fcsFile;
        self.parentGates      = gatesData;
        self.plotOptions      = plotOptions;
        self.subset           = subset;
        self.subsetCount      = subsetCount;
        self.subsetCalculated = NO;
    }
    return self;
}

- (void)main
{
    if (self.isCancelled) {
        return;
    }
    
    @autoreleasepool {
        
        if (self.parentGates.count > 0 && self.subset == nil) {
            NSLog(@"Will calculate subset");
            self.gateCalculator = [FGGateCalculator eventsInsideGatesWithDatas:self.parentGates fcsFile:self.fcsFile];
            self.subset         = self.gateCalculator.eventsInside;
            self.subsetCount    = self.gateCalculator.countOfEventsInside;
            self.subsetCalculated = YES;
        }
        if (self.isCancelled) {
            return;
        }
        NSLog(@"Will calculate plot data");
        self.plotDataCalculator = [FGPlotDataCalculator plotDataForFCSFile:self.fcsFile plotOptions:self.plotOptions subset:self.subset subsetCount:self.subsetCount];
        
        if (self.isCancelled) {
            return;
        }
        [(NSObject *)self.delegate performSelector:@selector(plotDataOperationDidFinish:) onThread:[NSThread mainThread] withObject:self waitUntilDone:NO];
    }
}

- (BOOL)hasCalculatedSubet
{
    return self.subsetCalculated;
}


@end
