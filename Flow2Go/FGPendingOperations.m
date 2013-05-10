//
//  FGPendingOperations.m
//  Flow2Go
//
//  Created by Christian Hansen on 26/03/13.
//  Copyright (c) 2013 Christian Hansen. All rights reserved.
//

#import "FGPendingOperations.h"
#import "FGGateCalculationOperation.h"

@implementation FGPendingOperations

+ (FGPendingOperations *)sharedInstance
{
    static FGPendingOperations *_pendingOperations = nil;
	if (_pendingOperations == nil) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            _pendingOperations = [[FGPendingOperations alloc] init];
        });
	}
    return _pendingOperations;
}


- (NSOperationQueue *)gateCalculationQueue
{
    if (_gateCalculationQueue == nil) {
        _gateCalculationQueue = [[NSOperationQueue alloc] init];
        _gateCalculationQueue.maxConcurrentOperationCount = 1;
        _gateCalculationQueue.name = @"Flow2Go Gate Calculation Queue";
    }
    return _gateCalculationQueue;
}

- (NSOperationQueue *)fcsParsingQueue
{
    if (_fcsParsingQueue == nil) {
        _fcsParsingQueue = [[NSOperationQueue alloc] init];
        _fcsParsingQueue.maxConcurrentOperationCount = 1;
        _fcsParsingQueue.name = @"Flow2Go FCS Parsing Queue";
    }
    return _fcsParsingQueue;
}


- (NSOperationQueue *)plotCreatorQueue
{
    if (_plotCreatorQueue == nil) {
        _plotCreatorQueue = [[NSOperationQueue alloc] init];
        _plotCreatorQueue.maxConcurrentOperationCount = 1;
        _plotCreatorQueue.name = @"Flow2Go Plot Creator Queue";
    }
    return _plotCreatorQueue;
}

- (void)cancelOperationsForGateWithTag:(NSInteger)gateTag
{
    NSArray *waitingOperations = self.gateCalculationQueue.operations;
    for (FGGateCalculationOperation *gateOperation in waitingOperations) {
        if (gateOperation.gateTag == gateTag) {
            [gateOperation cancel];
        }
    }
}

- (void)unregisterForObservings:(id)objectToUnregister
{
    NSArray *waitingOperations = self.gateCalculationQueue.operations;
    for (FGGateCalculationOperation *gateOperation in waitingOperations) {
        [gateOperation removeObserver:objectToUnregister forKeyPath:@"isExcuting" context:NULL];
        [gateOperation removeObserver:objectToUnregister forKeyPath:@"isFinished" context:NULL];
    }
}



@end
