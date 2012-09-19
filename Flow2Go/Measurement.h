//
//  Measurement.h
//  Flow2Go
//
//  Created by Christian Hansen on 26/08/12.
//  Copyright (c) 2012 Christian Hansen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Analysis, Folder, Keyword;

@interface Measurement : NSManagedObject

+ (Measurement *)createWithDictionary:(NSDictionary *)dictionary inContext:(NSManagedObjectContext *)context;

- (Keyword *)keywordWithKey:(NSString *)key;

+ (void)deleteMeasurement:(Measurement *)measurement;
+ (void)deleteMeasurements:(NSArray *)measurements;


@property (nonatomic, retain) NSNumber * countOfEvents;
@property (nonatomic, retain) NSDate * downloadDate;
@property (nonatomic, retain) NSString * filename;
@property (nonatomic, retain) NSString * filepath;
@property (nonatomic, retain) NSDate * lastModificationDate;
@property (nonatomic, retain) NSString * uniqueID;
@property (nonatomic, retain) NSOrderedSet *analyses;
@property (nonatomic, retain) NSSet *keywords;
@property (nonatomic, retain) Folder *folder;

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

- (void)addKeywordsObject:(Keyword *)value;
- (void)removeKeywordsObject:(Keyword *)value;
- (void)addKeywords:(NSSet *)values;
- (void)removeKeywords:(NSSet *)values;

@end
