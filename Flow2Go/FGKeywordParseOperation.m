//
//  FGKeywordParseOperation.m
//  Flow2Go
//
//  Created by Christian Hansen on 08/03/13.
//  Copyright (c) 2013 Christian Hansen. All rights reserved.
//

#import "FGKeywordParseOperation.h"
#import "FGFCSFile.h"

@implementation FGKeywordParseOperation

- (id)initWithFilePath:(NSString *)filePath
{
    if (self = [super init]) {
        self.fcsFilePath = filePath;
    }
    return self;
}


- (void)main
{
    if (self.isCancelled) {
        return;
    }
    self.fcsKeywords = [FGFCSFile fcsKeywordsWithFCSFileAtPath:self.fcsFilePath];
}

@end
