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

// FCS file specific
#define HEADER_LENGTH 58

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

+ (NSInteger)parameterNumberForShortName:(NSString *)PiNShortName inFCSFile:(FGFCSFile *)fcsFile;
+ (NSString *)parameterShortNameForParameterIndex:(NSInteger)parameterIndex inFCSFile:(FGFCSFile *)fcsFile;
+ (NSString *)parameterNameForParameterIndex:(NSInteger)parameterIndex inFCSFile:(FGFCSFile *)fcsFile;
- (NSInteger)rangeOfParameterIndex:(NSInteger)parameterIndex;
+ (FGAxisType)axisTypeForScaleString:(NSString *)scaleString;
- (FGAxisType)axisTypeForParameterIndex:(NSInteger)parameterIndex;

@property (nonatomic) double **events;
@property (nonatomic) FGRange *ranges;

@property (nonatomic, strong) NSDictionary *calibrationUnitNames;
@property (nonatomic, strong) NSDictionary *text;
@property (nonatomic, strong) NSDictionary *analysis;
@property (nonatomic) NSUInteger noOfEvents;
@property (nonatomic) NSUInteger noOfParams;
@property (nonatomic) FGParsingSegment parsingSegment;

@end


@interface FGFCSHeader : NSObject

@property (nonatomic) NSUInteger textBegin;
@property (nonatomic) NSUInteger textEnd;
@property (nonatomic) NSUInteger dataBegin;
@property (nonatomic) NSUInteger dataEnd;
@property (nonatomic) NSUInteger analysisBegin;
@property (nonatomic) NSUInteger analysisEnd;

@end
