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
#import "FileMD5Hash.h"
#import "FGKeyword.h"

@implementation FGMeasurement (Management)

- (NSError *)readInFCSKeyWords
{
    if (self.isDownloaded) {
        NSDictionary *fcsKeywords = [FCSFile fcsKeywordsWithFCSFileAtPath:[HOME_DIR stringByAppendingPathComponent:self.filePath]];
        self.countOfEvents = [NSNumber numberWithInteger:[fcsKeywords[@"$TOT"] integerValue]];
        [self _addKeywordsWithDictionary:fcsKeywords];
    } else {
        return [NSError errorWithDomain:@"com.flow2go.fcskeywords" code:44 userInfo:@{@"userInfo": @"Error: Can't parse Keywords, FCS file not downloaded"}];
    }
    return nil;
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


- (NSString *)md5Hash
{
    NSString *md5Hash;
    NSString *executablePath = self.fullFilePath.copy;
    CFStringRef executableFileMD5Hash = FileMD5HashCreateWithPath((CFStringRef)CFBridgingRetain(executablePath), FileHashDefaultChunkSizeForReadingData);
    if (executableFileMD5Hash) {
        md5Hash = ((NSString *)CFBridgingRelease(executableFileMD5Hash));
//        CFRelease(executableFileMD5Hash);
    }
    return md5Hash;
}


- (void)_addKeywordsWithDictionary:(NSDictionary *)dictionary
{
    for (NSString *key in dictionary.allKeys) {
        FGKeyword *keyword = [FGKeyword createInContext:self.managedObjectContext];
        if (dictionary[key] == nil || key == nil) {
            continue;
        }
        keyword.key = key;
        keyword.value = dictionary[key];
        
        if (keyword) {
            FGKeyword *existingKeyword = [self existingKeywordForKey:keyword.key];
            if (existingKeyword) {
                [self removeKeywordsObject:existingKeyword];
            }
            [self addKeywordsObject:keyword];
        }
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
