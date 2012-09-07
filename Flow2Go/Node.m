//
//  Node.m
//  Flow2Go
//
//  Created by Christian Hansen on 21/08/12.
//  Copyright (c) 2012 Christian Hansen. All rights reserved.
//

#import "Node.h"
#import "Analysis.h"
#import "Node.h"
#import "Measurement.h"
#import "Keyword.h"

@implementation Node

@dynamic xParName;
@dynamic xParNumber;
@dynamic yParName;
@dynamic yParNumber;
@dynamic analysis;
@dynamic childNodes;
@dynamic parentNode;
@dynamic name;
@dynamic dateCreated;
@dynamic needsUpdate;

- (void)setXParNumber:(NSNumber *)newXParNumber
{
    if (newXParNumber.integerValue != self.xParNumber.integerValue)
    {
        [self willChangeValueForKey:@"xParNumber"];
        [self setPrimitiveValue:newXParNumber forKey:@"xParNumber"];
        [self didChangeValueForKey:@"xParNumber"];
        
        NSString *shortNameKey = [@"$P" stringByAppendingFormat:@"%iN", newXParNumber.integerValue];
        Keyword *parNameKeyword = [self.analysis.measurement keywordWithKey:shortNameKey];
        self.xParName = parNameKeyword.value;
    }
}


- (void)setYParNumber:(NSNumber *)newYParNumber
{
    if (newYParNumber.integerValue != self.yParNumber.integerValue)
    {
        [self willChangeValueForKey:@"yParNumber"];
        [self setPrimitiveValue:newYParNumber forKey:@"yParNumber"];
        [self didChangeValueForKey:@"yParNumber"];
        
        NSString *shortNameKey = [@"$P" stringByAppendingFormat:@"%iN", newYParNumber.integerValue];
        Keyword *parNameKeyword = [self.analysis.measurement keywordWithKey:shortNameKey];
        self.yParName = parNameKeyword.value;
    }
}


@end
