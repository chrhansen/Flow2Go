//
//  FGMeasurement+Management.m
//  Flow2Go
//
//  Created by Christian Hansen on 05/02/13.
//  Copyright (c) 2013 Christian Hansen. All rights reserved.
//

#import "FGMeasurement+Management.h"
#import <DropboxSDK/DBMetadata.h>
#import "FGFCSFile.h"
#import "FileMD5Hash.h"
#import "FGKeyword.h"

@implementation FGMeasurement (Management)

- (NSError *)parseFCSKeyWords
{
    if ([self state] == FGDownloadStateDownloaded) {
        NSDictionary *textKeyValuePairs = [FGFCSFile fcsKeywordsWithFCSFileAtPath:self.fullFilePath];
        [self _addKeywordsWithDictionary:textKeyValuePairs];
        self.countOfEvents = [NSNumber numberWithInteger:[textKeyValuePairs[@"$TOT"] integerValue]];
    } else {
        return [NSError errorWithDomain:@"io.flow2go.fcskeywords" code:44 userInfo:@{NSLocalizedDescriptionKey : @"Error: Can't parse Keywords, FCS file not downloaded"}];
    }
    return nil;
}


+ (NSError *)_obtainPermanentIDs:(NSArray *)managedObjects
{
    NSManagedObjectContext *context = [NSManagedObjectContext contextForCurrentThread];
    NSError *error;
    [context obtainPermanentIDsForObjects:managedObjects error:&error];
    return error;
}

+ (NSError *)deleteMeasurements:(NSArray *)measurementsToDelete;
{
    NSError *permanentIDError = [self _obtainPermanentIDs:measurementsToDelete];
    if (permanentIDError) {
        return permanentIDError;
    }
    NSMutableArray *objectIDs = [NSMutableArray array];
    for (NSManagedObject *anObject in measurementsToDelete){
        [objectIDs addObject:anObject.objectID];
    }
    __block NSError *error;
    [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {
        for (NSManagedObjectID *anID in objectIDs) {
            FGMeasurement *aMeasurment = (FGMeasurement *)[localContext existingObjectWithID:anID error:&error];
            if (error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSLog(@"Error: could not retrieve existing object from objectID: %@", error.localizedDescription);
                });
            }
            error = [FGMeasurement deleteMeasurement:aMeasurment];
            if (error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSLog(@"Error: could not delete measurement and/or measurement file: %@", error.localizedDescription);
                });
            }
        }
    }];
    return error;
}


+ (NSError *)deleteMeasurement:(FGMeasurement *)measurement
{
    NSError *error = [self _obtainPermanentIDs:@[measurement]];
    if (error) {
        return error;
    }
    [NSFileManager.defaultManager removeItemAtPath:measurement.enclosingFolder error:&error];
    [measurement deleteInContext:measurement.managedObjectContext];
    return error;
}

- (NSString *)md5Hash
{
    NSString *md5Hash;
    NSString *executablePath = self.fullFilePath.copy;
    CFStringRef executableFileMD5Hash = FileMD5HashCreateWithPath((CFStringRef)CFBridgingRetain(executablePath), FileHashDefaultChunkSizeForReadingData);
    if (executableFileMD5Hash) {
        md5Hash = ((NSString *)CFBridgingRelease(executableFileMD5Hash));
    }
    return md5Hash;
}


- (FGDownloadState)state;
{
    return self.downloadState.integerValue;
}


- (void)setState:(FGDownloadState)downloadState
{
    if (downloadState != self.downloadState.integerValue) self.downloadState = [NSNumber numberWithInteger:downloadState];
}



- (void)_addKeywordsWithDictionary:(NSDictionary *)dictionary
{
    for (NSString *key in dictionary.allKeys) {
        if (!key) continue;
        
        FGKeyword *keyword = [self existingKeywordForKey:key];
        if (!keyword) {
            keyword = [FGKeyword createInContext:self.managedObjectContext];
            keyword.key = key;
        }
        keyword.value = dictionary[key];
        [self addKeywordsObject:keyword];
    }
}


- (FGKeyword *)existingKeywordForKey:(NSString *)key
{
    for (FGKeyword *aKeyword in self.keywords) {
        if ([aKeyword.key isEqualToString:key]) {
            return aKeyword;
        }
    }
    return nil;
}


- (FGFileType)fileType
{
    return [self.class fileTypeForFileName:self.filename];
}

+ (FGFileType)fileTypeForFileName:(NSString *)fileNameWithExtension
{
    NSString *extension = fileNameWithExtension.pathExtension.lowercaseString;
    if ([extension isEqualToString:@"lmd"]) {
        return FGFileTypeLMD;
    } else if ([extension isEqualToString:@"fcs"]) {
        return FGFileTypeFCS;
    }
    return FGFileTypeUnknown;
}

- (NSString *)fullFilePath
{
    return [HOME_DIR stringByAppendingPathComponent:self.filePath];
}

- (NSString *)enclosingFolder
{
    return self.fullFilePath.stringByDeletingLastPathComponent;
}


- (NSString *)downloadDateAsLocalizedString
{
    NSDateFormatter *format = [[NSDateFormatter alloc] init];
    [format setDateFormat:@"MMM dd, YYYY, HH:mm"];
    return [format stringFromDate:self.downloadDate];
}


- (void)setFilePath:(NSString *)filePath
{
    [self willChangeValueForKey:@"filePath"];
    [self setPrimitiveValue:filePath forKey:@"filePath"];
    [self didChangeValueForKey:@"filePath"];
    self.filename = filePath.lastPathComponent;
}

- (void)setThumbImage:(UIImage *)thumbImage
{
    [self willChangeValueForKey:@"thumbImage"];
    
    NSData *data = UIImagePNGRepresentation(thumbImage);
    [self setPrimitiveValue:data forKey:@"thumbImage"];
    [self didChangeValueForKey:@"thumbImage"];
}

- (UIImage*)thumbImage
{
    [self willAccessValueForKey:@"thumbImage"];
    UIImage *image = [UIImage imageWithData:[self primitiveValueForKey:@"thumbImage"]];
    [self didAccessValueForKey:@"thumbImage"];
    return image;
}


@end
