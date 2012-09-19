//
//  Measurement.m
//  Flow2Go
//
//  Created by Christian Hansen on 26/08/12.
//  Copyright (c) 2012 Christian Hansen. All rights reserved.
//

#import "Measurement.h"
#import "Analysis.h"
#import "Keyword.h"
#import <DropboxSDK/DBMetadata.h>
#import "FCSFile.h"
#import "NSString+UUID.h"
#import "NSData+MD5.h"

@implementation Measurement

@dynamic countOfEvents;
@dynamic downloadDate;
@dynamic filename;
@dynamic filepath;
@dynamic lastModificationDate;
@dynamic uniqueID;
@dynamic analyses;
@dynamic keywords;
@dynamic folder;

+ (Measurement *)createWithDictionary:(NSDictionary *)dictionary inContext:(NSManagedObjectContext *)context
{
    if (context == nil) context = [NSManagedObjectContext MR_contextForCurrentThread];
    Measurement *newMeasurement = [Measurement findFirstByAttribute:@"uniqueID" withValue:dictionary[@"uniqueID"] inContext:context];
    
    if (newMeasurement == nil)
    {
        newMeasurement = [Measurement createInContext:context];
        newMeasurement.uniqueID = dictionary[@"uniqueID"];
    }
    
    DBMetadata *metaData = dictionary[@"metadata"];
    newMeasurement.filename = metaData.filename;
    newMeasurement.filepath = dictionary[@"filepath"];
    
    if (dictionary[@"downloadDate"])
    {
        newMeasurement.downloadDate = dictionary[@"downloadDate"];
        NSDictionary *fcsKeywords = [FCSFile fcsKeywordsWithFCSFileAtPath:[HOME_DIR stringByAppendingPathComponent:newMeasurement.filepath]];
        newMeasurement.countOfEvents = [NSNumber numberWithInteger:[fcsKeywords[@"$TOT"] integerValue]];
        [newMeasurement _addKeywordsWithDictionary:fcsKeywords];
    }
    return newMeasurement;
}


+ (void)deleteMeasurements:(NSArray *)measurements
{
    for (Measurement *aMeasurement in measurements)
    {
        [Measurement deleteMeasurement:aMeasurement];
    }
}


+ (void)deleteMeasurement:(Measurement *)measurement
{
    NSManagedObjectContext *localContext = [NSManagedObjectContext contextForCurrentThread];

    if (measurement)
    {
        NSError *error;
        [NSFileManager.defaultManager removeItemAtPath:[HOME_DIR stringByAppendingPathComponent:measurement.filepath] error:&error];
        if (error)
        {
            NSLog(@"Error: file could not be deleted: %@", error.localizedDescription);
        }
        [measurement deleteInContext:measurement.managedObjectContext];
        [localContext save];
    }
}

- (NSString *)md5OfFile:(NSString *)filePath
{
    NSURL *URL = [NSURL URLWithString:filePath relativeToURL:HOME_URL];
    NSData *data = [NSData dataWithContentsOfURL:URL];
    return [data md5];
}


- (void)_addKeywordsWithDictionary:(NSDictionary *)dictionary
{
    for (NSString *key in dictionary.allKeys)
    {
        Keyword *aKeyword = [Keyword createWithValue:dictionary[key] forKey:key];
        if (aKeyword)
        {
            Keyword *existingKeyword = [self keywordWithKey:aKeyword.key];
            if (existingKeyword)
            {
                [self removeKeywordsObject:existingKeyword];
            }
            [self addKeywordsObject:aKeyword];
        }
    }
}


- (Keyword *)keywordWithKey:(NSString *)key
{
    for (Keyword *aKeyword in self.keywords)
    {
        if ([aKeyword.key isEqualToString:key])
        {
            return aKeyword;
        }
    }
    return nil;
}

@end
