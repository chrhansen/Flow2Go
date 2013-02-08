//
//  FGFolder+Management.h
//  Flow2Go
//
//  Created by Christian Hansen on 05/02/13.
//  Copyright (c) 2013 Christian Hansen. All rights reserved.
//

#import "FGFolder.h"

@interface FGFolder (Management)

+ (void)deleteFolders:(NSArray *)foldersToDelete completion:(void (^)(NSError *error))completion;
+ (void)createWithName:(NSString *)folderName;
- (NSDate *)downloadDateOfNewestMeasurement;

@end
