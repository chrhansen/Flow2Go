//
//  Keyword.m
//  Flow2Go
//
//  Created by Christian Hansen on 26/08/12.
//  Copyright (c) 2012 Christian Hansen. All rights reserved.
//

#import "Keyword.h"
#import "Measurement.h"


@implementation Keyword

@dynamic key;
@dynamic value;
@dynamic measurement;

+ (Keyword *)createWithValue:(NSString *)value forKey:(NSString *)key
{
    if (!value
        || !key)
    {
        return nil;
    }
    
    Keyword *keyword = [Keyword createEntity];
    
    keyword.key = key;
    keyword.value = value;

    return keyword;
}


@end
