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


- (void)main
{
    if (self.isCancelled) {
        return;
    }

    @autoreleasepool {
        
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
        
        self.subSet = [NSData dataWithBytes:(NSUInteger *)gateCalculator.eventsInside length:sizeof(NSUInteger)*gateCalculator.countOfEventsInside];
        self.subSetCount = gateCalculator.countOfEventsInside;
        
        if (self.isCancelled) {
            return;
        }
        
        [(NSObject *)self.delegate performSelector:@selector(gateCalculationOperationDidFinish:) onThread:[NSThread mainThread] withObject:self waitUntilDone:NO];
    }
}

@end
