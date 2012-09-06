//
//  Node.h
//  Flow2Go
//
//  Created by Christian Hansen on 21/08/12.
//  Copyright (c) 2012 Christian Hansen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Analysis, Node;

@interface Node : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * xParName;
@property (nonatomic, retain) NSNumber * xParNumber;
@property (nonatomic, retain) NSString * yParName;
@property (nonatomic, retain) NSNumber * yParNumber;
@property (nonatomic, retain) Analysis *analysis;
@property (nonatomic, retain) NSOrderedSet *childNodes;
@property (nonatomic, retain) Node *parentNode;
@property (nonatomic, retain) NSDate *dateCreated;

@end

@interface Node (CoreDataGeneratedAccessors)

- (void)insertObject:(Node *)value inChildNodesAtIndex:(NSUInteger)idx;
- (void)removeObjectFromChildNodesAtIndex:(NSUInteger)idx;
- (void)insertChildNodes:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeChildNodesAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInChildNodesAtIndex:(NSUInteger)idx withObject:(Node *)value;
- (void)replaceChildNodesAtIndexes:(NSIndexSet *)indexes withChildNodes:(NSArray *)values;
- (void)addChildNodesObject:(Node *)value;
- (void)removeChildNodesObject:(Node *)value;
- (void)addChildNodes:(NSOrderedSet *)values;
- (void)removeChildNodes:(NSOrderedSet *)values;

@end
