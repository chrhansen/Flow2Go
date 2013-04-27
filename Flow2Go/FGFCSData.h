//
//  FGFCSData.h
//  Flow2Go
//
//  Created by Christian Hansen on 26/04/13.
//  Copyright (c) 2013 Christian Hansen. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, FGParameterSize)
{
    FGParameterSizeUnknown,
    FGParameterSize8,
    FGParameterSize16,
    FGParameterSize32,
};

@interface FGFCSData : NSObject

- (NSError *)parseDataSegmentFromData:(NSData *)dataSegmentData fcsKeywords:(NSDictionary *)keywords;

@property (nonatomic) NSUInteger noOfEvents;
@property (nonatomic) NSUInteger noOfParams;
@property (nonatomic, strong) NSDictionary *calibrationUnitNames;

@property (nonatomic) double **events;
@property (nonatomic) FGRange *ranges;

@end
