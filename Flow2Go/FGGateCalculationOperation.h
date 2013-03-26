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

- (id)initWithVertices:(NSArray *)vertices
               gateTag:(NSInteger)gateTag
              gateType:(FGGateType)gateType
               fcsFile:(FGFCSFile *)fcsFile
           plotOptions:(NSDictionary *)plotOptions
          parentSubSet:(NSData *)parentSubSet
     parentSubSetCount:(NSUInteger)parentSubSetCount
              delegate:(id<FGGateCalculationOperationDelegate>)delegate;

@property (nonatomic, strong) NSArray *vertices;
@property (nonatomic) FGGateType gateType;
@property (nonatomic) NSInteger gateTag;
@property (nonatomic, strong) FGFCSFile *fcsFile;
@property (nonatomic, strong) NSDictionary *plotOptions;
@property (nonatomic, strong) NSData *parentSubSet;
@property (nonatomic) NSUInteger parentSubSetCount;

@property (nonatomic, weak) id<FGGateCalculationOperationDelegate> delegate;
@property (nonatomic, strong) NSData *subSet;
@property (nonatomic) NSUInteger subSetCount;

@end
