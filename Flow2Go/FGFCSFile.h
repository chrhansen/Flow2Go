//
//  FCSFile.h
//  Flow2Go
//
//  Created by Christian Hansen on 05/08/12.
//  Copyright (c) 2012 Christian Hansen. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "FGFCSText.h"
#import "FGFCSData.h"

@class FGFCSFile;

@protocol FGFCSProgressDelegate <NSObject>
- (void)loadProgress:(CGFloat)progress forFCSFile:(FGFCSFile *)fcsFile;
@end

typedef NS_ENUM(NSInteger, FGParsingSegment) {
    FGParsingSegmentBegan,
    FGParsingSegmentHeader,
    FGParsingSegmentText,
    FGParsingSegmentData,
    FGParsingSegmentAnalysis,
    FGParsingSegmentFinished,
    FGParsingSegmentFailed
};

@interface FGFCSFile : NSObject

+ (FGFCSFile *)fcsFileWithPath:(NSString *)path lastParsingSegment:(FGParsingSegment)lastSegment error:(NSError **)error;
+ (NSDictionary *)fcsKeywordsWithFCSFileAtPath:(NSString *)path;
- (void)readFCSFileAtPath:(NSString *)path progressDelegate:(id<FGFCSProgressDelegate>)progressDelegate withCompletion:(void (^)(NSError *error))completion;


- (NSInteger)rangeOfParameterIndex:(NSInteger)parameterIndex;
+ (FGAxisType)axisTypeForScaleString:(NSString *)scaleString;
- (FGAxisType)axisTypeForParameterIndex:(NSInteger)parameterIndex;

@property (nonatomic, strong) FGFCSText *text;
@property (nonatomic, strong) FGFCSData *data;
@property (nonatomic, strong) NSDictionary *keywords;
@property (nonatomic, strong) NSDictionary *analysisKeywords;
@property (nonatomic) FGParsingSegment parsingSegment;

@end

