//
//  FGMeasurement+Management.m
//  Flow2Go
//
//  Created by Christian Hansen on 05/02/13.
//  Copyright (c) 2013 Christian Hansen. All rights reserved.
//

#import "FGMeasurement+Management.h"
#import <DropboxSDK/DBMetadata.h>
#import "FCSFile.h"
#import "NSData+MD5.h"
#import "FGKeyword+Management.h"

@implementation FGMeasurement (Management)

+ (FGMeasurement *)createWithDictionary:(NSDictionary *)dictionary inContext:(NSManagedObjectContext *)context
{
    if (context == nil) context = [NSManagedObjectContext MR_contextForCurrentThread];
    FGMeasurement *newMeasurement = [FGMeasurement findFirstByAttribute:@"fGMeasurementID" withValue:dictionary[@"fGMeasurementID"] inContext:context];
    
    if (newMeasurement == nil) {
        newMeasurement = [FGMeasurement createInContext:context];
        newMeasurement.fGMeasurementID = dictionary[@"fGMeasurementID"];
    }
    newMeasurement.filePath = dictionary[@"filepath"];
    
    if (dictionary[@"downloadDate"]) {
        newMeasurement.downloadDate = dictionary[@"downloadDate"];
        NSDictionary *fcsKeywords = [FCSFile fcsKeywordsWithFCSFileAtPath:[HOME_DIR stringByAppendingPathComponent:newMeasurement.filePath]];
        newMeasurement.countOfEvents = [NSNumber numberWithInteger:[fcsKeywords[@"$TOT"] integerValue]];
        [newMeasurement _addKeywordsWithDictionary:fcsKeywords];
    }
    return newMeasurement;
}


+ (void)deleteMeasurements:(NSArray *)measurements
{
    for (FGMeasurement *aMeasurement in measurements) {
        [FGMeasurement deleteMeasurement:aMeasurement];
    }
}


+ (void)deleteMeasurement:(FGMeasurement *)measurement
{
    NSManagedObjectID *objectID = measurement.objectID;
    __block NSError *fileError;
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        FGMeasurement *localMeasurement = (FGMeasurement *)[localContext objectWithID:objectID];
        if (localMeasurement) {
            NSError *fileError;
            [NSFileManager.defaultManager removeItemAtPath:[HOME_DIR stringByAppendingPathComponent:measurement.filePath] error:&fileError];
            [localMeasurement deleteInContext:localContext];
        }
    } completion:^(BOOL success, NSError *error) {
        if (fileError) NSLog(@"Error: file could not be deleted: %@", fileError.localizedDescription);
        if (error) NSLog(@"Error: deleting object: %@", error.localizedDescription);
    }];
}


- (NSString *)md5OfFile:(NSString *)filePath
{
    NSURL *URL = [NSURL URLWithString:filePath relativeToURL:HOME_URL];
    NSData *data = [NSData dataWithContentsOfURL:URL];
    return [data md5];
}


- (void)_addKeywordsWithDictionary:(NSDictionary *)dictionary
{
    for (NSString *key in dictionary.allKeys) {
        FGKeyword *aKeyword = [FGKeyword createWithValue:dictionary[key] forKey:key];
        if (aKeyword) {
            FGKeyword *existingKeyword = [self keywordWithKey:aKeyword.key];
            if (existingKeyword) {
                [self removeKeywordsObject:existingKeyword];
            }
            [self addKeywordsObject:aKeyword];
        }
    }
}


- (FGKeyword *)keywordWithKey:(NSString *)key
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

- (BOOL)isDownloaded
{
    NSArray *pathComponents = [self.filePath pathComponents];
    return (pathComponents.count > 0 && [pathComponents[0] isEqualToString:@"Documents"]);
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

@end
