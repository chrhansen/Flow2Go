//
//  FGFCSParserOperation.h
//  Flow2Go
//
//  Created by Christian Hansen on 26/04/13.
//  Copyright (c) 2013 Christian Hansen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FGFCSFile.h"

@class FGFCSParserOperation;

@protocol FGFCSParserOperationDelegate <NSObject>

@optional
- (void)fcsParserOperationProgress:(CGFloat *)progress;

@end

@interface FGFCSParserOperation : NSOperation

- (id)initWithFCSFileAtPath:(NSString *)path lastParsingSegment:(FGParsingSegment)lastSegment;
- (void)setCompletionBlock:(void (^)(NSError *error, FGFCSFile *fcsFile))completion;

@property (nonatomic, weak) id<FGFCSParserOperationDelegate> delegate; // Not implemented

@end
