//
//  Measurement.h
//  Flow2Go
//
//  Created by Christian Hansen on 21/08/12.
//  Copyright (c) 2012 Christian Hansen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Analysis;

@interface Measurement : NSManagedObject

+ (Measurement *)createWithDictionary:(NSDictionary *)dictionary;

@property (nonatomic, retain) NSNumber * countOfEvents;
@property (nonatomic, retain) NSString * filename;
@property (nonatomic, retain) NSString * filepath;
@property (nonatomic, retain) NSString * uniqueID;
@property (nonatomic, retain) NSDate * downloadDate;
@property (nonatomic, retain) NSOrderedSet *analyses;
@end

@interface Measurement (CoreDataGeneratedAccessors)

- (void)insertObject:(Analysis *)value inAnalysesAtIndex:(NSUInteger)idx;
- (void)removeObjectFromAnalysesAtIndex:(NSUInteger)idx;
- (void)insertAnalyses:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeAnalysesAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInAnalysesAtIndex:(NSUInteger)idx withObject:(Analysis *)value;
- (void)replaceAnalysesAtIndexes:(NSIndexSet *)indexes withAnalyses:(NSArray *)values;
- (void)addAnalysesObject:(Analysis *)value;
- (void)removeAnalysesObject:(Analysis *)value;
- (void)addAnalyses:(NSOrderedSet *)values;
- (void)removeAnalyses:(NSOrderedSet *)values;

@end
