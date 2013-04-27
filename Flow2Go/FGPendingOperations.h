//
//  FGPendingOperations.h
//  Flow2Go
//
//  Created by Christian Hansen on 26/03/13.
//  Copyright (c) 2013 Christian Hansen. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FGPendingOperations : NSObject

+ (FGPendingOperations *)sharedInstance;

- (void)cancelOperationsForGateWithTag:(NSInteger)gateTag;
- (void)unregisterForObservings:(id)objectToUnregister;

@property (nonatomic, strong) NSOperationQueue *gateCalculationQueue;
@property (nonatomic, strong) NSOperationQueue *fcsParsingQueue;

@end
