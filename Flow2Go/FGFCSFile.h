//
//  FCSFile.h
//  Flow2Go
//
//  Created by Christian Hansen on 05/08/12.
//  Copyright (c) 2012 Christian Hansen. All rights reserved.
//

#import <Foundation/Foundation.h>
@class FGFCSFile;
@protocol FGFCSProgressDelegate <NSObject>

- (void)loadProgress:(CGFloat)progress forFCSFile:(FGFCSFile *)fcsFile;

@end


@interface FGFCSFile : NSObject

+ (FGFCSFile *)fcsFileWithPath:(NSString *)path error:(NSError **)error;
+ (NSDictionary *)fcsKeywordsWithFCSFileAtPath:(NSString *)path;
+ (void)readFCSFileAtPath:(NSString *)path progressDelegate:(id<FGFCSProgressDelegate>)progressDelegate withCompletion:(void (^)(NSError *error, FGFCSFile *fcsFile))completion;

- (void)cleanUpEvents;

+ (NSInteger)parameterNumberForName:(NSString *)PiNShortName inFCSFile:(FGFCSFile *)fcsFile;
+ (NSString *)parameterShortNameForParameterIndex:(NSInteger)parameterIndex inFCSFile:(FGFCSFile *)fcsFile;
+ (NSString *)parameterNameForParameterIndex:(NSInteger)parameterIndex inFCSFile:(FGFCSFile *)fcsFile;
- (NSInteger)rangeOfParameterIndex:(NSInteger)parameterIndex;
- (FGAxisType)axisTypeForParameterIndex:(NSInteger)parameterIndex;

@property (nonatomic) double **events;
@property (nonatomic) FGRange *ranges;

@property (nonatomic, strong) NSDictionary *calibrationUnitNames;
@property (nonatomic, strong) NSDictionary *text;
@property (nonatomic, strong) NSDictionary *analysis;
@property (nonatomic) NSUInteger noOfEvents;
@property (nonatomic) NSUInteger noOfParams;

@end
