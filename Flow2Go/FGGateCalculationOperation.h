//
//  FGGateCalculationOperation.h
//  Flow2Go
//
//  Created by Christian Hansen on 26/03/13.
//  Copyright (c) 2013 Christian Hansen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FGGateCalculator.h"

@class FGFCSFile, FGGateCalculationOperation;

@interface FGGateCalculationOperation : NSOperation

- (id)initWithGateData:(NSDictionary *)gateData fcsFile:(FGFCSFile *)fcsFile parentSubSet:(NSUInteger *)parentSubSet parentSubSetCount:(NSUInteger)parentSubSetCount;

// When multiple nested gates exist, the subset will be assumed to be all events in the FCS-file
- (id)initWithGateDatas:(NSArray *)gateDatas fcsFile:(FGFCSFile *)fcsFile;
- (void)setCompletionBlock:(void (^)(NSError *error, NSData *subset, NSUInteger subsetCount))completion; 

@property (nonatomic, strong) FGFCSFile *fcsFile;
@property (nonatomic) NSInteger gateTag;

@end
