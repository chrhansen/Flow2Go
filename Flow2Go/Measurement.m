//
//  Measurement.m
//  Flow2Go
//
//  Created by Christian Hansen on 21/08/12.
//  Copyright (c) 2012 Christian Hansen. All rights reserved.
//

#import "Measurement.h"
#import "Analysis.h"
#import <DropboxSDK/DBMetadata.h>
#import "FCSFile.h"
#import "NSString+UUID.h"

@implementation Measurement

@dynamic countOfEvents;
@dynamic filename;
@dynamic filepath;
@dynamic uniqueID;
@dynamic downloadDate;
@dynamic analyses;

+ (Measurement *)createWithDictionary:(NSDictionary *)dictionary
{
    DBMetadata *metaData = dictionary[@"metadata"];
    Measurement *newMeasurement = [Measurement findFirstByAttribute:@"uniqueID" withValue:dictionary[@"uniqueID"]];
    
    NSLog(@"filename: %@", metaData.filename);
    
    if (newMeasurement == nil)
    {
        newMeasurement = [Measurement createEntity];
        newMeasurement.uniqueID = dictionary[@"uniqueID"];
    }

    newMeasurement.filename = metaData.filename;
    newMeasurement.filepath = dictionary[@"filepath"];

    if (dictionary[@"downloadDate"])
    {
        newMeasurement.downloadDate = dictionary[@"downloadDate"];
        NSDictionary *fcsKeywords = [FCSFile fcsKeywordsWithFCSFileAtPath:[HOME_DIR stringByAppendingPathComponent:newMeasurement.filepath]];
        newMeasurement.countOfEvents = [NSNumber numberWithInteger:[fcsKeywords[@"$TOT"] integerValue]];
    }

    return newMeasurement;
}


@end
