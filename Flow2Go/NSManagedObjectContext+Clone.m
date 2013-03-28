//
//  NSManagedObjectContext+Clone.m
//  Flow2Go
//
//  Created by Christian Hansen on 28/03/13.
//  Copyright (c) 2013 Christian Hansen. All rights reserved.
//

#import "NSManagedObjectContext+Clone.h"

@implementation NSManagedObjectContext (Clone)

- (NSManagedObject *)clone:(NSManagedObject *)source
{
    NSString *entityName = [[source entity] name];
    
    //create new object in data store
    NSManagedObject *cloned = [NSEntityDescription
                               insertNewObjectForEntityForName:entityName
                               inManagedObjectContext:self];
    
    //loop through all attributes and assign then to the clone
    NSDictionary *attributes = [[NSEntityDescription
                                 entityForName:entityName
                                 inManagedObjectContext:self] attributesByName];
    
    for (NSString *attr in attributes) {
        [cloned setValue:[source valueForKey:attr] forKey:attr];
    }
    
    //Loop through all relationships, and clone them.
    NSDictionary *relationships = [[NSEntityDescription
                                    entityForName:entityName
                                    inManagedObjectContext:self] relationshipsByName];
    
    for (NSString *relName in [relationships allKeys]){
        
        NSRelationshipDescription *rel = [relationships objectForKey:relName];
        if ([rel isToMany]) {
            //get a set of all objects in the relationship
            
            if ([rel isOrdered]) {
                NSArray *sourceArray = [[source mutableOrderedSetValueForKey:relName] array];
                NSMutableOrderedSet *clonedSet = [cloned mutableOrderedSetValueForKey:relName];
                for(NSManagedObject *relatedObject in sourceArray) {
                    if ([relName isEqualToString:@"gates"]) {
                        //
                        NSLog(@"gates rel. %d", sourceArray.count);
                    }
                    NSManagedObject *clonedRelatedObject = [self clone:relatedObject];
                    [clonedSet addObject:clonedRelatedObject];
                }
            } else {
                //get a set of all objects in the relationship
                NSArray *sourceArray = [[source mutableSetValueForKey:relName] allObjects];
                NSMutableSet *clonedSet = [cloned mutableSetValueForKey:relName];
                for(NSManagedObject *relatedObject in sourceArray) {
                    NSManagedObject *clonedRelatedObject = [self clone:relatedObject];
                    [clonedSet addObject:clonedRelatedObject];
                }
            }
        } else {
            [cloned setValue:[source valueForKey:relName] forKey:relName];
        }
        
    }
    
    return cloned;
}

@end
