//
//  FGMeasurement.h
//  Flow2Go
//
//  Created by Christian Hansen on 08/05/13.
//  Copyright (c) 2013 Christian Hansen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class FGAnalysis, FGFolder, FGKeyword;

@interface FGMeasurement : NSManagedObject

@property (nonatomic, retain) NSNumber * countOfEvents;
@property (nonatomic, retain) NSDate * downloadDate;
@property (nonatomic, retain) NSString * fGMeasurementID;
@property (nonatomic, retain) NSString * filename;
@property (nonatomic, retain) NSString * filePath;
@property (nonatomic, retain) NSString * globalURL;
@property (nonatomic, retain) NSString * md5FileHash;
@property (nonatomic, retain) UIImage * thumbImage;
@property (nonatomic, retain) NSNumber * downloadState;
@property (nonatomic, retain) NSOrderedSet *analyses;
@property (nonatomic, retain) FGFolder *folder;
@property (nonatomic, retain) NSSet *keywords;
@end

@interface FGMeasurement (CoreDataGeneratedAccessors)

- (void)insertObject:(FGAnalysis *)value inAnalysesAtIndex:(NSUInteger)idx;
- (void)removeObjectFromAnalysesAtIndex:(NSUInteger)idx;
- (void)insertAnalyses:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeAnalysesAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInAnalysesAtIndex:(NSUInteger)idx withObject:(FGAnalysis *)value;
- (void)replaceAnalysesAtIndexes:(NSIndexSet *)indexes withAnalyses:(NSArray *)values;
- (void)addAnalysesObject:(FGAnalysis *)value;
- (void)removeAnalysesObject:(FGAnalysis *)value;
- (void)addAnalyses:(NSOrderedSet *)values;
- (void)removeAnalyses:(NSOrderedSet *)values;
- (void)addKeywordsObject:(FGKeyword *)value;
- (void)removeKeywordsObject:(FGKeyword *)value;
- (void)addKeywords:(NSSet *)values;
- (void)removeKeywords:(NSSet *)values;

@end
