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

@implementation Measurement

@dynamic countOfEvents;
@dynamic filename;
@dynamic filepath;
@dynamic lastModificationDate;
@dynamic measurementDate;
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
    newMeasurement.lastModificationDate = NSDate.date;
    newMeasurement.filepath = dictionary[@"filepath"];
    
    return newMeasurement;
}

- (Analysis *)lastViewedAnalysis
{
    //NSData *date = NSDate.date;
    Analysis *lastViewed;
    for (Analysis *anAnalysis in self.analyses) {
        // <#statements#>
    }
    return lastViewed;
}

@end
