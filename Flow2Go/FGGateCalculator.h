//
//  Gate.h
//  Flow2Go
//
//  Created by Christian Hansen on 14/08/12.
//  Copyright (c) 2012 Christian Hansen. All rights reserved.
//

#import <Foundation/Foundation.h>
@class FGFCSFile;

@interface FGGateCalculator : NSObject

+ (FGGateCalculator *)eventsInsideGateWithData:(NSDictionary *)gateData
                                       fcsFile:(FGFCSFile *)fcsFile
                                        subSet:(NSUInteger *)subSet
                                   subSetCount:(NSUInteger)subSetCount;


+ (FGGateCalculator *)eventsInsideGateWithXParameter:(NSString *)xParShortName
                                          yParameter:(NSString *)yParShortName
                                            gateType:(FGGateType)gateType
                                            vertices:(NSArray *)vertices
                                             fcsFile:(FGFCSFile *)fcsFile
                                              subSet:(NSUInteger *)subSet
                                         subSetCount:(NSUInteger)subSetCount;

+ (void)eventsInsideGateWithXParameter:(NSString *)xParShortName
                            yParameter:(NSString *)yParShortName
                              gateType:(FGGateType)gateType
                              vertices:(NSArray *)vertices
                               fcsFile:(FGFCSFile *)fcsFile
                                subSet:(NSUInteger *)subSet
                           subSetCount:(NSUInteger)subSetCount
                            completion:(void (^)(NSData *subset, NSUInteger numberOfCellsInside))completion;

@property (nonatomic) NSUInteger *eventsInside;
@property (nonatomic) NSUInteger countOfEventsInside;

@end
