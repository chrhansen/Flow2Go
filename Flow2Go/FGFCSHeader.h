//
//  FGFCSHeader.h
//  Flow2Go
//
//  Created by Christian Hansen on 26/04/13.
//  Copyright (c) 2013 Christian Hansen. All rights reserved.
//

#import <Foundation/Foundation.h>

// FCS file specific
#define HEADER_LENGTH 58

@interface FGFCSHeader : NSObject

- (NSError *)parseHeaderSegmentFromData:(NSData *)stringASCIIData;

@property (nonatomic) NSUInteger textBegin;
@property (nonatomic) NSUInteger textEnd;
@property (nonatomic) NSUInteger textLength;

@property (nonatomic) NSUInteger dataBegin;
@property (nonatomic) NSUInteger dataEnd;
@property (nonatomic) NSUInteger dataLength;

@property (nonatomic) NSUInteger analysisBegin;
@property (nonatomic) NSUInteger analysisEnd;
@property (nonatomic) NSUInteger analysisLength;

@end
