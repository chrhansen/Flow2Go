//
//  FGGate+Management.m
//  Flow2Go
//
//  Created by Christian Hansen on 05/02/13.
//  Copyright (c) 2013 Christian Hansen. All rights reserved.
//

#import "FGGate+Management.h"

#import "FGAnalysis+Management.h"
#import "FGKeyword.h"
#import "FGMeasurement+Management.h"

@implementation FGGate (Management)

- (void)setXParNumber:(NSNumber *)newXParNumber
{
    if (newXParNumber.integerValue != self.xParNumber.integerValue)
    {
        [self willChangeValueForKey:@"xParNumber"];
        [self setPrimitiveValue:newXParNumber forKey:@"xParNumber"];
        [self didChangeValueForKey:@"xParNumber"];
        
        NSString *shortNameKey = [@"$P" stringByAppendingFormat:@"%iN", newXParNumber.integerValue];
        FGKeyword *parNameKeyword = [self.analysis.measurement existingKeywordForKey:shortNameKey];
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
        FGKeyword *parNameKeyword = [self.analysis.measurement existingKeywordForKey:shortNameKey];
        self.yParName = parNameKeyword.value;
    }
}

@end
