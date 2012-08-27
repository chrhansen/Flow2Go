//
//  Keyword.h
//  Flow2Go
//
//  Created by Christian Hansen on 26/08/12.
//  Copyright (c) 2012 Christian Hansen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Measurement;

@interface Keyword : NSManagedObject

+ (Keyword *)createWithValue:(NSString *)value forKey:(NSString *)key;

@property (nonatomic, retain) NSString * key;
@property (nonatomic, retain) NSString * value;
@property (nonatomic, retain) Measurement *measurement;

@end
