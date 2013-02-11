//
//  NSDate+Formatting.m
//  Flow2Go
//
//  Created by Christian Hansen on 11/02/13.
//  Copyright (c) 2013 Christian Hansen. All rights reserved.
//

#import "NSDate+Formatting.h"

@implementation NSDate (Formatting)

- (NSString *)readableDate
{
    static NSDateFormatter *dateFormatter = nil;
    if (dateFormatter == nil) {
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
        [dateFormatter setLocale:[NSLocale currentLocale]];
        [dateFormatter setDoesRelativeDateFormatting:YES];
        [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
    }
    NSString *dateString = [dateFormatter stringFromDate:self];
    if (dateString.length > 0) {
        NSString *firstCapChar = [[dateString substringToIndex:1] capitalizedString];
        dateString = [dateString stringByReplacingCharactersInRange:NSMakeRange(0,1) withString:firstCapChar];
    }
    return dateString;
}

@end
