//
//  NSArrayValueTransformer.m
//  Winning Coach
//
//  Created by Christian Hansen on 4/4/12.
//  Copyright (c) 2012 BYTEPOETS GmbH. All rights reserved.
//

#import "NSArrayValueTransformer.h"

@implementation NSArrayValueTransformer

+ (Class)transformedValueClass 
{ 
    return NSArray.class;
}


+ (BOOL)allowsReverseTransformation 
{ 
    return YES; 
}


- (id)transformedValue:(id)value 
{
    if (value == nil) {
        return nil;
    }
    
    return [NSKeyedArchiver archivedDataWithRootObject:value];
}


- (id)reverseTransformedValue:(id)value
{
    if (value == nil) {
        return nil;
    }
    
    return [NSKeyedUnarchiver unarchiveObjectWithData:value];
}

@end
