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

@protocol FGGateCalculationOperationDelegate <NSObject>

- (void)gateCalculationOperationDidFinish:(FGGateCalculationOperation *)operation;

@end

@interface FGGateCalculationOperation : NSOperation

- (id)initWithGateData:(NSDictionary *)gateData
               fcsFile:(FGFCSFile *)fcsFile
          parentSubSet:(NSUInteger *)parentSubSet
     parentSubSetCount:(NSUInteger)parentSubSetCount;

@property (nonatomic, strong) NSDictionary *gateData;
@property (nonatomic) NSInteger gateTag;
@property (nonatomic, strong) FGFCSFile *fcsFile;
@property (nonatomic) NSUInteger *parentSubSet;
@property (nonatomic) NSUInteger parentSubSetCount;

@property (nonatomic, weak) id<FGGateCalculationOperationDelegate> delegate;
@property (nonatomic, strong) NSData *subSet;
@property (nonatomic) NSUInteger subSetCount;

@end
