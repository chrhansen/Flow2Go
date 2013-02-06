//
//  FGKeyword+Management.h
//  Flow2Go
//
//  Created by Christian Hansen on 05/02/13.
//  Copyright (c) 2013 Christian Hansen. All rights reserved.
//

#import "FGKeyword.h"

@interface FGKeyword (Management)

+ (FGKeyword *)createWithValue:(NSString *)value forKey:(NSString *)key;

@end
