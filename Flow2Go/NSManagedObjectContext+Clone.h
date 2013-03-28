//
//  NSManagedObjectContext+Clone.h
//  Flow2Go
//
//  Created by Christian Hansen on 28/03/13.
//  Copyright (c) 2013 Christian Hansen. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface NSManagedObjectContext (Clone)

- (NSManagedObject *)clone:(NSManagedObject *)source;

@end
