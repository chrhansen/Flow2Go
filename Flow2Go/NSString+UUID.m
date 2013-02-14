//
//  NSString+UUID.m
//  Flow2Go
//
//  Created by Christian Hansen on 26/08/12.
//  Copyright (c) 2012 Christian Hansen. All rights reserved.
//

#import "NSString+UUID.h"

@implementation NSString (UUID)

+ (NSString *)getUUID
{
    CFUUIDRef uuid = CFUUIDCreate(NULL);
    NSString *uuidStr = (__bridge_transfer NSString *)CFUUIDCreateString(NULL, uuid);
    CFRelease(uuid);
    return uuidStr;
}


+ (NSString *)percentageAsString:(NSInteger)subsetCount ofAll:(NSInteger)totalCount
{
    if (totalCount == 0 ) return @"0%";
    
    double subset = (double)subsetCount;
    double total = (double)totalCount;
    
    return [NSString stringWithFormat:@"%.1f%%", 100.0*subset/total];
}


+ (NSString *)countsAndPercentageAsString:(NSInteger)subsetCount ofAll:(NSInteger)totalCount
{
    if (totalCount == 0 ) return @"0%";
    
    double subset = (double)subsetCount;
    double total = (double)totalCount;
    
    return [NSString stringWithFormat:@"%d/%d (%.1f%%)", subsetCount, totalCount, 100.0*subset/total];
}
@end
