//
//  FCSFile.m
//  Flow2Go
//
//  Created by Christian Hansen on 05/08/12.
//  Copyright (c) 2012 Christian Hansen. All rights reserved.
//

#import "FGFCSFile.h"
#import "FGFCSHeader.h"
#import "FGFCSAnalysis.h"

@interface FGFCSFile ()

@property (nonatomic, strong) FGFCSHeader *header;
@property (nonatomic, strong) FGFCSAnalysis *analysis;

@end

@implementation FGFCSFile

- (void)readFCSFileAtPath:(NSString *)path progressDelegate:(id<FGFCSProgressDelegate>)progressDelegate withCompletion:(void (^)(NSError *error))completion
{
    NSError *error = [self.class checkFilePath:path];
    if (error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(error);
        });
        return;
    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSError *error = [self _parseFileFromPath:path lastParsingSegment:FGParsingSegmentAnalysis];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion(error);
            }
        });
    });
}


+ (FGFCSFile *)fcsFileWithPath:(NSString *)path lastParsingSegment:(FGParsingSegment)lastSegment error:(NSError **)error
{
    FGFCSFile *newFCSFile = [FGFCSFile.alloc init];
    *error = [newFCSFile _parseFileFromPath:path lastParsingSegment:lastSegment];
    
    if (!*error) return newFCSFile;
    
    return nil;
}


+ (NSError *)checkFilePath:(NSString *)path
{
    NSError *error;
    if (!path) error = [NSError errorWithDomain:@"io.flow2go.fcsparser" code:-100 userInfo:@{NSLocalizedDescriptionKey : @"Error: Path for FCS file is nil."}];
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) error = [NSError errorWithDomain:@"io.flow2go.fcsparser" code:-100 userInfo:@{NSLocalizedDescriptionKey: @"Error: no file at specified path."}];
    return error;
}

- (id)init
{
    self = [super init];
    if (self) {
        self.parsingSegment = FGParsingSegmentBegan;
    }
    return self;
}

+ (NSDictionary *)fcsKeywordsWithFCSFileAtPath:(NSString *)path
{
    FGFCSFile *newFCSFile = [FGFCSFile.alloc init];
    [newFCSFile _parseFileFromPath:path lastParsingSegment:FGParsingSegmentText];
    return newFCSFile.keywords;
}


- (NSError *)_parseFileFromPath:(NSString *)path lastParsingSegment:(FGParsingSegment)lastParsingSegment;
{
    NSError *error;

    self.parsingSegment = FGParsingSegmentBegan;
    //Load NSData object
    NSData *allFCSData = [NSData dataWithContentsOfFile:path options:NSDataReadingMappedIfSafe error:&error];
    
    //Read header string
    self.parsingSegment = FGParsingSegmentHeader;
    self.header = [[FGFCSHeader alloc] init];
    error = [self.header parseHeaderSegmentFromData:[allFCSData subdataWithRange:NSMakeRange(0, HEADER_LENGTH)]];
    if (!error) {
        self.parsingSegment = (FGParsingSegmentHeader == lastParsingSegment) ? FGParsingSegmentFinished : FGParsingSegmentText;
    } else {
        self.parsingSegment = FGParsingSegmentFailed;
    }
    
    //Parse text segment
    if (self.parsingSegment == FGParsingSegmentText) {
        self.text = [[FGFCSText alloc] init];
        error = [self.text parseTextSegmentFromData:[allFCSData subdataWithRange:NSMakeRange(self.header.textBegin, self.header.textLength)]];
        if (!error) {
            self.parsingSegment = (FGParsingSegmentText == lastParsingSegment) ? FGParsingSegmentFinished : FGParsingSegmentData;
        } else {
            self.parsingSegment = FGParsingSegmentFailed;
        }
    }
    
    //Parse data segment
    if (self.parsingSegment == FGParsingSegmentData) {
        self.data = [[FGFCSData alloc] init];
        error = [self.data parseDataSegmentFromData:[allFCSData subdataWithRange:NSMakeRange(self.header.dataBegin, self.header.dataLength)] fcsKeywords:self.text.keywords];
        if (!error) {
            self.parsingSegment = (FGParsingSegmentData == lastParsingSegment) ? FGParsingSegmentFinished : FGParsingSegmentAnalysis;
        } else {
            self.parsingSegment = FGParsingSegmentFailed;
        }
    }
    
    //Parse Analysis segment
    if (self.parsingSegment == FGParsingSegmentAnalysis) {
        self.analysis = [[FGFCSAnalysis alloc] init];
        error = [self.analysis parseAnalysisSegmentFromData:[allFCSData subdataWithRange:NSMakeRange(self.header.analysisBegin, self.header.analysisLength)] seperator:self.text.seperatorCharacterset];
        self.parsingSegment = (!error) ? FGParsingSegmentFinished : FGParsingSegmentFailed;
    }
    
    //Round up
    if (self.parsingSegment == FGParsingSegmentFinished || _parsingSegment == FGParsingSegmentFailed) {
        allFCSData = nil;
    }
    
    return error;
}


- (void)_printOutRange:(NSRange)range forParameter:(NSInteger)parNo
{
    for (NSUInteger i = range.location; i < range.location + range.length; i++)
    {
        NSLog(@"eventNo:%i, parNo:(%i) , value: %f", i, parNo, self.data.events[i][parNo - 1]);
    }
}


- (void)_printOutRange:(NSRange)range
{
    for (NSUInteger parNo = 0; parNo < self.data.noOfParams; parNo++) {
        for (NSUInteger i = range.location; i < range.location + range.length; i++) {
            NSLog(@"ParNo:(%i), eventNo:%i, value: %f", parNo + 1, i + 1, self.data.events[i][parNo]);
        }
        NSLog(@"\n");
    }
}



- (void)_printOutScaledMinMax
{
    for (NSUInteger parNo = 0; parNo < self.data.noOfParams ; parNo++)
    {
        double maxValue, minValue;
        minValue = maxValue = self.data.events[0][parNo];
        for (NSUInteger eventNo = 0; eventNo < self.data.noOfEvents; eventNo++)
        {
            if (self.data.events[eventNo][parNo] > maxValue)
            {
                maxValue = self.data.events[eventNo][parNo];
            }
            if (self.data.events[eventNo][parNo] < minValue)
            {
                minValue = self.data.events[eventNo][parNo];
            }
        }
        NSLog(@"Actual Par %i, min: %f, max: %f", parNo + 1, minValue, maxValue);
    }
}



- (NSInteger)rangeOfParameterIndex:(NSInteger)parameterIndex
{
    NSString *rangeKey = [@"$P" stringByAppendingFormat:@"%iR", parameterIndex + 1];
    return [self.text.keywords[rangeKey] integerValue];
}


+ (FGAxisType)axisTypeForScaleString:(NSString *)scaleString
{
    if (!scaleString) {
        return kAxisTypeUnknown;
    }
    NSArray *scaleComponents = [scaleString componentsSeparatedByString:@","];
    double f1 = [scaleComponents[0] doubleValue];
  
    return (f1 <= 0.0) ? kAxisTypeLinear : kAxisTypeLogarithmic;
}

- (FGAxisType)axisTypeForParameterIndex:(NSInteger)parameterIndex
{
    NSString *scaleString = self.text.keywords[[@"$P" stringByAppendingFormat:@"%iE", parameterIndex + 1]];
    if (!scaleString) NSLog(@"Required scale Value for par %i not found.", parameterIndex + 1);
    
    return [self.class axisTypeForScaleString:scaleString];
}


- (NSDictionary *)keywords
{
    return self.text.keywords;
}


@end
