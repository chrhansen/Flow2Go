//
//  FGFCSParserOperation.m
//  Flow2Go
//
//  Created by Christian Hansen on 26/04/13.
//  Copyright (c) 2013 Christian Hansen. All rights reserved.
//

#import "FGFCSParserOperation.h"

@interface FGFCSParserOperation ()

@property (nonatomic, strong) NSString *path;
@property (nonatomic) FGParsingSegment lastSegment;
@property (nonatomic, copy) void (^finishedParsingCompletionBlock)(NSError *error, FGFCSFile *fcsFile);

@end

@implementation FGFCSParserOperation

- (id)initWithFCSFileAtPath:(NSString *)path lastParsingSegment:(FGParsingSegment)lastSegment
{
    self = [super init];
    if (self) {
        self.path = path;
        self.lastSegment = lastSegment;
    }
    return self;
}

- (void)setCompletionBlock:(void (^)(NSError *, FGFCSFile *))completion
{
    _finishedParsingCompletionBlock = completion;
}


- (void)main
{
    if (self.isCancelled || !self.path) {
        return;
    }
    
    @autoreleasepool {
        NSError *error;
        FGFCSFile *fcsFile = [FGFCSFile fcsFileWithPath:self.path lastParsingSegment:self.lastSegment error:&error];
        
        if (self.isCancelled) {
            return;
        }
        
        self.finishedParsingCompletionBlock(error, fcsFile);
        
//        [(NSObject *)self.delegate performSelector:@selector(fcsParserOperationProgress:) onThread:[NSThread mainThread] withObject:[NSNumber numberWithFloat:progress] waitUntilDone:NO];
    }
}



@end
