//
//  FGAnalysis.h
//  Flow2Go
//
//  Created by Christian Hansen on 05/02/13.
//  Copyright (c) 2013 Christian Hansen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class FGGate, FGMeasurement, FGPlot;

@interface FGAnalysis : NSManagedObject

@property (nonatomic, retain) NSDate * dateModified;
@property (nonatomic, retain) NSDate * dateViewed;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSOrderedSet *gates;
@property (nonatomic, retain) FGMeasurement *measurement;
@property (nonatomic, retain) NSOrderedSet *plots;
@end

@interface FGAnalysis (CoreDataGeneratedAccessors)

- (void)insertObject:(FGGate *)value inGatesAtIndex:(NSUInteger)idx;
- (void)removeObjectFromGatesAtIndex:(NSUInteger)idx;
- (void)insertGates:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeGatesAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInGatesAtIndex:(NSUInteger)idx withObject:(FGGate *)value;
- (void)replaceGatesAtIndexes:(NSIndexSet *)indexes withGates:(NSArray *)values;
- (void)addGatesObject:(FGGate *)value;
- (void)removeGatesObject:(FGGate *)value;
- (void)addGates:(NSOrderedSet *)values;
- (void)removeGates:(NSOrderedSet *)values;
- (void)insertObject:(FGPlot *)value inPlotsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromPlotsAtIndex:(NSUInteger)idx;
- (void)insertPlots:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removePlotsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInPlotsAtIndex:(NSUInteger)idx withObject:(FGPlot *)value;
- (void)replacePlotsAtIndexes:(NSIndexSet *)indexes withPlots:(NSArray *)values;
- (void)addPlotsObject:(FGPlot *)value;
- (void)removePlotsObject:(FGPlot *)value;
- (void)addPlots:(NSOrderedSet *)values;
- (void)removePlots:(NSOrderedSet *)values;
@end
