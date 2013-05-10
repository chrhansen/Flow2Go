//
//  FGFCSAnalysis.m
//  Flow2Go
//
//  Created by Christian Hansen on 26/04/13.
//  Copyright (c) 2013 Christian Hansen. All rights reserved.
//

#import "FGFCSAnalysis.h"

@implementation FGFCSAnalysis

- (NSError *)parseAnalysisSegmentFromData:(NSData *)analysisData seperator:(NSCharacterSet *)seperatorCharacterset
{
    if (analysisData.length == 0) {
        return nil;
    }
    
    uint8_t buffer[analysisData.length];
    [analysisData getBytes:buffer length:analysisData.length];
    NSString *analysisString = [[NSString alloc] initWithBytes:buffer length:sizeof(buffer) encoding:NSASCIIStringEncoding];
    
    if (!analysisString) {
        return [NSError errorWithDomain:@"io.flow2go.fcsparser.analysissegment" code:-100 userInfo:@{NSLocalizedDescriptionKey: @"Error: analysis could not be read in FCS file"}];
    }
    
    if (!seperatorCharacterset) {
        return [NSError errorWithDomain:@"io.flow2go.fcsparser.analysissegment" code:-100 userInfo:@{NSLocalizedDescriptionKey: @"Error: separator not set in analysis segment."}];
    }
    
    NSError *error;
    
    @try {
        NSArray *textSeparated = [[analysisString substringFromIndex:1] componentsSeparatedByCharactersInSet:seperatorCharacterset];
        
        NSMutableDictionary *analysisKeyValuePairs = [NSMutableDictionary dictionary];
        
        for (int i = 0; i < textSeparated.count; i += 2)
        {
            if (i + 1 < textSeparated.count)
            {
                analysisKeyValuePairs[[textSeparated[i] uppercaseString]] = textSeparated[i+1];
            }
        }
        
        if (analysisKeyValuePairs.count > 0)
        {
            self.analysisKeywords = [NSDictionary dictionaryWithDictionary:analysisKeyValuePairs];
        }
        error = [NSError errorWithDomain:@"io.flow2go.fcsparser.analysissegment" code:-100 userInfo:@{NSLocalizedDescriptionKey: @"Error: no keywords could be read in the analysis segment."}];
    }
    @catch (NSException *exception) {
        error = [NSError errorWithDomain:@"io.flow2go.fcsparser.analysissegment" code:-100 userInfo:@{NSLocalizedDescriptionKey: exception.reason}];
    }
    @finally {
        // Nothing
    }
    return error;
}

@end
