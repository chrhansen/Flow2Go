//
//  FGKeywordParseOperation.h
//  Flow2Go
//
//  Created by Christian Hansen on 08/03/13.
//  Copyright (c) 2013 Christian Hansen. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FGKeywordParseOperation : NSOperation

@property (nonatomic, strong) NSString *fcsFilePath;
@property (nonatomic, strong) NSDictionary *fcsKeywords;

@end
