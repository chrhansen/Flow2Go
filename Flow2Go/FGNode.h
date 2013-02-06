//
//  FGNode.h
//  Flow2Go
//
//  Created by Christian Hansen on 05/02/13.
//  Copyright (c) 2013 Christian Hansen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class FGNode;

@interface FGNode : NSManagedObject

@property (nonatomic, retain) NSDate * dateCreated;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * needsUpdate;
@property (nonatomic, retain) NSString * xParName;
@property (nonatomic, retain) NSNumber * xParNumber;
@property (nonatomic, retain) NSString * yParName;
@property (nonatomic, retain) NSNumber * yParNumber;
@property (nonatomic, retain) NSOrderedSet *childNodes;
@property (nonatomic, retain) FGNode *parentNode;
@end

@interface FGNode (CoreDataGeneratedAccessors)

- (void)insertObject:(FGNode *)value inChildNodesAtIndex:(NSUInteger)idx;
- (void)removeObjectFromChildNodesAtIndex:(NSUInteger)idx;
- (void)insertChildNodes:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeChildNodesAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInChildNodesAtIndex:(NSUInteger)idx withObject:(FGNode *)value;
- (void)replaceChildNodesAtIndexes:(NSIndexSet *)indexes withChildNodes:(NSArray *)values;
- (void)addChildNodesObject:(FGNode *)value;
- (void)removeChildNodesObject:(FGNode *)value;
- (void)addChildNodes:(NSOrderedSet *)values;
- (void)removeChildNodes:(NSOrderedSet *)values;
@end
