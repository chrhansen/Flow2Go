//
//  FCSFile20Text.h
//  FCSViewer
//
//  Created by Christian Hansen on 2/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FCSFile20Text : NSObject

+ (FCSFile20Text *)textWithFCSFile:(NSString *)fcsFile inRange:(NSRange)aRange;

@property (nonatomic, strong) NSDictionary *dictionary;
@property (nonatomic) NSUInteger noOfParameters;
@property (nonatomic, strong) NSArray *parameterRanges;
@property (nonatomic) NSUInteger *parameterRange;
@property (nonatomic, strong) NSArray *parameterNames;

@end
