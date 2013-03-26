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


@implementation FGGateCalculationOperation

- (id)initWithVertices:(NSArray *)vertices
               gateTag:(NSInteger)gateTag
              gateType:(FGGateType)gateType
               fcsFile:(FGFCSFile *)fcsFile
           plotOptions:(NSDictionary *)plotOptions
          parentSubSet:(NSData *)parentSubSet
     parentSubSetCount:(NSUInteger)parentSubSetCount
              delegate:(id<FGGateCalculationOperationDelegate>)delegate
{
    if (self = [super init]) {
        self.vertices          = vertices;
        self.gateTag           = gateTag;
        self.gateType          = gateType;
        self.fcsFile           = fcsFile;
        self.plotOptions       = plotOptions;
        self.parentSubSet      = parentSubSet;
        self.parentSubSetCount = parentSubSetCount;
        self.delegate = delegate;
    }
    return self;
}

- (void)main
{
    if (self.isCancelled) {
        return;
    }

    @autoreleasepool {
        NSUInteger *parentSubSetBytes = nil;
        if (self.parentSubSet) {
            parentSubSetBytes = calloc(self.parentSubSetCount, sizeof(NSUInteger *));
            memcpy(parentSubSetBytes, [self.parentSubSet bytes], [self.parentSubSet length]);
        }
        
        FGGateCalculator *gateCalculator = [FGGateCalculator eventsInsideGateWithVertices:self.vertices gateType:self.gateType fcsFile:self.fcsFile plotOptions:self.plotOptions subSet:parentSubSetBytes subSetCount:self.parentSubSetCount];
        
        if (self.isCancelled) {
            return;
        }
        
        NSData *subset = [NSData dataWithBytes:(NSUInteger *)gateCalculator.eventsInside length:sizeof(NSUInteger)*gateCalculator.numberOfCellsInside];
        self.subSet = subset.copy;
        self.subSetCount = gateCalculator.numberOfCellsInside;
        
        if (self.isCancelled) {
            return;
        }
        
        [(NSObject *)self.delegate performSelector:@selector(gateCalculationOperationDidFinish:) onThread:[NSThread mainThread] withObject:self waitUntilDone:NO];
    }
}

@end
