//
//  FGFCSText.h
//  Flow2Go
//
//  Created by Christian Hansen on 26/04/13.
//  Copyright (c) 2013 Christian Hansen. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FGFCSText : NSObject

- (NSError *)parseTextSegmentFromData:(NSData *)textASCIIData;

+ (NSInteger)parameterNumberForShortName:(NSString *)PiNShortName inFCSKeywords:(NSDictionary *)keywords;
+ (NSString *)parameterShortNameForParameterIndex:(NSInteger)parameterIndex inFCSKeywords:(NSDictionary *)keywords;
+ (NSString *)parameterNameForParameterIndex:(NSInteger)parameterIndex inFCSKeywords:(NSDictionary *)keywords;

@property (nonatomic, strong) NSDictionary *keywords;
@property (nonatomic, strong) NSCharacterSet *seperatorCharacterset;
@end
