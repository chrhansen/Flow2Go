//
//  FGGateCalculationOperation.m
//  Flow2Go
//
//  Created by Christian Hansen on 26/03/13.
//  Copyright (c) 2013 Christian Hansen. All rights reserved.
//

#import "FGGateCalculationOperation.h"
#import "FGFCSFile.h"
#import "FGPlot+Management.h"
#import "FGGate+Management.h"

@interface FGGateCalculationOperation ()

@property (nonatomic, copy) void (^gateCompletionBlock)(NSError *error, NSData *subset, NSUInteger subsetCount);
@property (nonatomic) NSUInteger *parentSubSet;
@property (nonatomic) NSUInteger parentSubSetCount;
@property (nonatomic, strong) NSArray *gateDatas;

@end

@implementation FGGateCalculationOperation

- (id)initWithGateData:(NSDictionary *)gateData
               fcsFile:(FGFCSFile *)fcsFile
          parentSubSet:(NSUInteger *)parentSubSet
     parentSubSetCount:(NSUInteger)parentSubSetCount
{
    if (self = [super init]) {
        self.gateDatas         = @[gateData];
        self.fcsFile           = fcsFile;
        self.parentSubSet      = parentSubSet;
        self.parentSubSetCount = parentSubSetCount;
    }
    return self;
}


- (id)initWithGateDatas:(NSArray *)gateDatas fcsFile:(FGFCSFile *)fcsFile
{
    if (self = [super init]) {
        self.gateDatas = gateDatas;
        self.fcsFile   = fcsFile;
    }
    return self;
}


- (void)setCompletionBlock:(void (^)(NSError *error, NSData *subset, NSUInteger subsetCount))completion
{
    _gateCompletionBlock = completion;
}


- (void)main
{
    if (self.isCancelled) {
        return;
    }

    @autoreleasepool {
        
        if (self.isCancelled) {
            return;
        }
        
        NSError *error;
        FGGateCalculator *gateCalculator;
        
        if (self.gateDatas) {
            gateCalculator = [FGGateCalculator eventsInsideGatesWithDatas:self.gateDatas
                                                                  fcsFile:self.fcsFile];

        } else {
            gateCalculator = [FGGateCalculator eventsInsideGateWithData:self.gateDatas.lastObject
                                                                fcsFile:self.fcsFile
                                                                 subSet:self.parentSubSet
                                                            subSetCount:self.parentSubSetCount];
        }
        
        
        if (self.isCancelled) {
            return;
        }
        
        NSData *subset = [NSData dataWithBytes:(NSUInteger *)gateCalculator.eventsInside length:sizeof(NSUInteger)*gateCalculator.countOfEventsInside];
        NSUInteger *subsetCount = gateCalculator.countOfEventsInside;
        
        if (self.isCancelled) {
            return;
        }
        
        self.gateCompletionBlock(error, subset, subsetCount);
        return;
    }
}

@end
