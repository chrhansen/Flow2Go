//
//  FGFolder+Management.m
//  Flow2Go
//
//  Created by Christian Hansen on 05/02/13.
//  Copyright (c) 2013 Christian Hansen. All rights reserved.
//

#import "FGFolder+Management.h"
#import "FGMeasurement+Management.h"

@implementation FGFolder (Management)
+ (void)createWithName:(NSString *)folderName
{
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        FGFolder *newFolder = [FGFolder createInContext:localContext];
        newFolder.name = folderName;
    }];
}


+ (void)deleteFolders:(NSArray *)foldersToDelete completion:(void (^)(NSError *error))completion
{
    NSManagedObjectContext *context = [NSManagedObjectContext contextForCurrentThread];
    NSError *permanentIDError;
    [context obtainPermanentIDsForObjects:foldersToDelete error:&permanentIDError];
    if (permanentIDError) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) completion(permanentIDError);
        });
        return;
    }
    NSMutableArray *objectIDs = [NSMutableArray array];
    for (NSManagedObject *anObject in foldersToDelete){
        [objectIDs addObject:anObject.objectID];
    }
    
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        for (NSManagedObjectID *anID in objectIDs) {
            NSError *error;
            FGFolder *aFolder = (FGFolder *)[localContext existingObjectWithID:anID error:&error];
            if (error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (completion) completion(error);
                });
                return;
            }
            error = [FGFolder deleteFolder:aFolder];
            if (error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (completion) completion(error);
                });
                return;
            }
        }
    }  completion:^(BOOL success, NSError *error) {
        NSAssert([NSThread isMainThread], @"Callback in delete is NOT on Main Thread");
        if (completion) completion(error);
    }];
}

+ (NSError *)deleteFolder:(FGFolder *)aFolder
{
    if ([aFolder deleteInContext:aFolder.managedObjectContext]) {
        return nil;
    } else {
        NSString *errorMessage = [NSString stringWithFormat:@"%@ %@", @"Error deleting folder:", aFolder.name];
        return [NSError errorWithDomain:@"flow2go.datamodel.folder" code:50 userInfo:@{@"userInfo": errorMessage}];
    }
}

- (NSDate *)downloadDateOfNewestMeasurement
{
    NSArray *measurements = self.measurements.array;
    NSArray *sortedArray = [measurements sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        FGMeasurement *meas1 = (FGMeasurement *)obj1;
        FGMeasurement *meas2 = (FGMeasurement *)obj2;
        return [meas1.downloadDate compare:meas2.downloadDate];
    }];
    FGMeasurement *newestMeasurement = sortedArray.lastObject;
    return newestMeasurement.downloadDate;
}
@end
