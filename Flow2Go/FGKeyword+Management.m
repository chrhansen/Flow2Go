//
//  FGKeyword+Management.m
//  Flow2Go
//
//  Created by Christian Hansen on 05/02/13.
//  Copyright (c) 2013 Christian Hansen. All rights reserved.
//

#import "FGKeyword+Management.h"

@implementation FGKeyword (Management)

+ (FGKeyword *)createWithValue:(NSString *)value forKey:(NSString *)key
{
    if (!value
        || !key) {
        return nil;
    }
    
    FGKeyword *keyword = [FGKeyword createEntity];
    
    keyword.key = key;
    keyword.value = value;
    
    return keyword;
}

@end
