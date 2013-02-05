//
//  FGFolder.h
//  Flow2Go
//
//  Created by Christian Hansen on 05/02/13.
//  Copyright (c) 2013 Christian Hansen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Measurement;

@interface FGFolder : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSOrderedSet *measurements;
@end

@interface FGFolder (CoreDataGeneratedAccessors)

- (void)insertObject:(Measurement *)value inMeasurementsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromMeasurementsAtIndex:(NSUInteger)idx;
- (void)insertMeasurements:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeMeasurementsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInMeasurementsAtIndex:(NSUInteger)idx withObject:(Measurement *)value;
- (void)replaceMeasurementsAtIndexes:(NSIndexSet *)indexes withMeasurements:(NSArray *)values;
- (void)addMeasurementsObject:(Measurement *)value;
- (void)removeMeasurementsObject:(Measurement *)value;
- (void)addMeasurements:(NSOrderedSet *)values;
- (void)removeMeasurements:(NSOrderedSet *)values;
@end
