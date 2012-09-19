//
//  Folder.m
//  Flow2Go
//
//  Created by Christian Hansen on 19/09/12.
//  Copyright (c) 2012 Christian Hansen. All rights reserved.
//

#import "Folder.h"
#import "Measurement.h"


@implementation Folder

@dynamic name;
@dynamic measurements;

+ (Folder *)createWithName:(NSString *)name
{
    Folder *newFolder = [Folder createInContext:NSManagedObjectContext.MR_defaultContext];
    newFolder.name = name;
    
    [newFolder.managedObjectContext save];
    
    return newFolder;
}


@end
