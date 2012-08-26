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

@end
