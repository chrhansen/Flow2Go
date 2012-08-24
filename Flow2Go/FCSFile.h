//
//  FCSFile.h
//  Flow2Go
//
//  Created by Christian Hansen on 05/08/12.
//  Copyright (c) 2012 Christian Hansen. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface FCSFile : NSObject

+ (FCSFile *)fcsFileWithPath:(NSString *)path;
+ (NSDictionary *)fcsKeywordsWithFCSFileAtPath:(NSString *)path;



+ (NSInteger)parameterNumberForName:(NSString *)PiNShortName inFCSFile:(FCSFile *)fcsFile;
+ (NSString *)parameterShortNameForParameterIndex:(NSInteger)parameterIndex inFCSFile:(FCSFile *)fcsFile;
+ (NSString *)parameterNameForParameterIndex:(NSInteger)parameterIndex inFCSFile:(FCSFile *)fcsFile;
- (NSInteger)rangeOfParameterIndex:(NSInteger)parameterIndex;
- (NSArray *)amplificationComponentsForParameterIndex:(NSInteger)parameterIndex;

@property (nonatomic) NSUInteger **event;
@property (nonatomic, strong) NSDictionary *text;
@property (nonatomic) NSUInteger noOfEvents;

@end
