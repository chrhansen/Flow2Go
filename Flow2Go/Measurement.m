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

@implementation Measurement

@dynamic countOfEvents;
@dynamic filename;
@dynamic filepath;
@dynamic downloadDate;
@dynamic analyses;

+ (Measurement *)createWithDictionary:(NSDictionary *)dictionary
{
    DBMetadata *metaData = dictionary[@"metadata"];
    Measurement *newMeasurement = [Measurement findFirstByAttribute:@"filename" withValue:metaData.filename];
    
    if (newMeasurement == nil)
    {
        newMeasurement = [Measurement createEntity];
    }
    
    newMeasurement.filename = metaData.filename;
    newMeasurement.filepath = dictionary[@"filepath"];
    newMeasurement.downloadDate = dictionary[@"downloadDate"];

    NSDictionary *fcsKeywords = [FCSFile fcsKeywordsWithFCSFileAtPath:newMeasurement.filepath];
    newMeasurement.countOfEvents = [NSNumber numberWithInteger:[fcsKeywords[@"$TOT"] integerValue]];
    return newMeasurement;
}


@end
