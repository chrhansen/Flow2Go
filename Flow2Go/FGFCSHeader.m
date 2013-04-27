//
//  FGFCSHeader.m
//  Flow2Go
//
//  Created by Christian Hansen on 26/04/13.
//  Copyright (c) 2013 Christian Hansen. All rights reserved.
//

#import "FGFCSHeader.h"

@implementation FGFCSHeader


- (NSError *)parseHeaderSegmentFromData:(NSData *)stringASCIIData
{
    NSString *headerString = [NSString.alloc initWithData:stringASCIIData encoding:NSASCIIStringEncoding];
    
    if (!headerString || headerString.length < HEADER_LENGTH) {
        return [NSError errorWithDomain:@"io.flow2go.fcsparser.headersegment" code:-100 userInfo:@{@"userInfo": @"Error: length of header in FCS file not correct."}];
    }
    self.textBegin     = [[headerString substringWithRange:NSMakeRange(10, 8)] integerValue];
    self.textEnd       = [[headerString substringWithRange:NSMakeRange(18, 8)] integerValue];
    self.dataBegin     = [[headerString substringWithRange:NSMakeRange(26, 8)] integerValue];
    self.dataEnd       = [[headerString substringWithRange:NSMakeRange(34, 8)] integerValue];
    self.analysisBegin = [[headerString substringWithRange:NSMakeRange(42, 8)] integerValue];
    self.analysisEnd   = [[headerString substringWithRange:NSMakeRange(50, 8)] integerValue];
    
    return nil;
}

- (NSUInteger)textLength
{
    if (self.textEnd == 0 || self.textBegin == 0) {
        return 0;
    }
    return self.textEnd - self.textBegin + 1;
}

- (NSUInteger)dataLength
{
    if (self.dataEnd == 0 || self.dataBegin == 0) {
        return 0;
    }
    return self.dataEnd - self.dataBegin + 1;
}

- (NSUInteger)analysisLength
{
    if (self.analysisEnd == 0 || self.analysisBegin == 0) {
        return 0;
    }
    return self.analysisEnd - self.analysisBegin + 1;
}


@end
