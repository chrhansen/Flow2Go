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

- (id)initWithXParameter:(NSString *)xParShortName
              yParameter:(NSString *)yParShortName
                gateType:(FGGateType)gateType
                vertices:(NSArray *)vertices
                 fcsFile:(FGFCSFile *)fcsFile
            parentSubSet:(NSUInteger *)parentSubSet
       parentSubSetCount:(NSUInteger)parentSubSetCount
{
    if (self = [super init]) {
        self.vertices          = vertices;
        self.gateType          = gateType;
        self.fcsFile           = fcsFile;
        self.xParShortName     = xParShortName;
        self.yParShortName     = yParShortName;
        self.parentSubSet      = parentSubSet;
        self.parentSubSetCount = parentSubSetCount;
    }
    return self;
}

- (void)main
{
    if (self.isCancelled) {
        return;
    }

    @autoreleasepool {
        
        FGGateCalculator *gateCalculator = [FGGateCalculator eventsInsideGateWithXParameter:self.xParShortName
                                                                                 yParameter:self.yParShortName
                                                                                   gateType:self.gateType
                                                                                   vertices:self.vertices
                                                                                    fcsFile:self.fcsFile
                                                                                     subSet:self.parentSubSet
                                                                                subSetCount:self.parentSubSetCount];
        
        if (self.isCancelled) {
            return;
        }
        
        NSData *subset = [NSData dataWithBytes:(NSUInteger *)gateCalculator.eventsInside length:sizeof(NSUInteger)*gateCalculator.countOfEventsInside];
        self.subSet = subset.copy;
        self.subSetCount = gateCalculator.countOfEventsInside;
        
        if (self.isCancelled) {
            return;
        }
        
        [(NSObject *)self.delegate performSelector:@selector(gateCalculationOperationDidFinish:) onThread:[NSThread mainThread] withObject:self waitUntilDone:NO];
    }
}

@end
