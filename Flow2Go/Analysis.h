//
//  Analysis.h
//  Flow2Go
//
//  Created by Christian Hansen on 21/08/12.
//  Copyright (c) 2012 Christian Hansen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Gate, Measurement, Plot;

@interface Analysis : NSManagedObject

+ (Analysis *)createAnalysisForMeasurement:(Measurement *)aMeasurement;

@property (nonatomic, retain) NSDate * dateModified;
@property (nonatomic, retain) NSDate * dateViewed;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) Measurement *measurement;
@property (nonatomic, retain) NSOrderedSet *plots;
@property (nonatomic, retain) NSOrderedSet *gates;
@end

@interface Analysis (CoreDataGeneratedAccessors)

- (void)insertObject:(Plot *)value inPlotsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromPlotsAtIndex:(NSUInteger)idx;
- (void)insertPlots:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removePlotsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInPlotsAtIndex:(NSUInteger)idx withObject:(Plot *)value;
- (void)replacePlotsAtIndexes:(NSIndexSet *)indexes withPlots:(NSArray *)values;
- (void)addPlotsObject:(Plot *)value;
- (void)removePlotsObject:(Plot *)value;
- (void)addPlots:(NSOrderedSet *)values;
- (void)removePlots:(NSOrderedSet *)values;

- (void)insertObject:(Gate *)value inGatesAtIndex:(NSUInteger)idx;
- (void)removeObjectFromGatesAtIndex:(NSUInteger)idx;
- (void)insertGates:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeGatesAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInGatesAtIndex:(NSUInteger)idx withObject:(Gate *)value;
- (void)replaceGatesAtIndexes:(NSIndexSet *)indexes withGates:(NSArray *)values;
- (void)addGatesObject:(Gate *)value;
- (void)removeGatesObject:(Gate *)value;
- (void)addGates:(NSOrderedSet *)values;
- (void)removeGates:(NSOrderedSet *)values;

@end
