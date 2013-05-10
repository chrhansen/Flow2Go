//
//  FGPlotCreatorOperation.m
//  Flow2Go
//
//  Created by Christian Hansen on 09/05/13.
//  Copyright (c) 2013 Christian Hansen. All rights reserved.
//

#import "FGPlotCreatorOperation.h"
#import "FGPlotCreator.h"

@interface FGPlotCreatorOperation ()

@property (nonatomic, strong) FGFCSFile *fcsFile;
@property (nonatomic, strong) NSDictionary *plotOptions;
@property (nonatomic, copy) void (^finishedPlottingCompletionBlock)(NSError *error, UIImage *image, UIImage *thumbNail);

@end


@implementation FGPlotCreatorOperation

- (id)initWithFCSFile:(FGFCSFile *)fcsFile plotOptions:(NSDictionary *)plotOptions
{
    self = [super init];
    if (self) {
        self.fcsFile = fcsFile;
        self.plotOptions = plotOptions;
    }
    return self;
}

- (void)setCompletionBlock:(void (^)(NSError *error, UIImage *image, UIImage *thumbNail))completion
{
    _finishedPlottingCompletionBlock = completion;
}


- (void)main
{
    if (self.isCancelled || !self.fcsFile) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            NSError *error;
            if (!self.fcsFile) {
                error = [NSError errorWithDomain:@"io.flow2go.plotcreateoperation" code:0 userInfo:@{NSLocalizedDescriptionKey: @"Error: No FCS File to create plot from"}];
            } else if (!self.plotOptions) {
                error = [NSError errorWithDomain:@"io.flow2go.plotcreateoperation" code:0 userInfo:@{NSLocalizedDescriptionKey: @"Error: No Plot settings to create plot from"}];
            }
            self.finishedPlottingCompletionBlock(error, nil, nil);
        }];
        return;
    }
    
    @autoreleasepool {
        if (self.isCancelled) {
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                self.finishedPlottingCompletionBlock(nil, nil, nil);
            }];
            return;
        }
        FGPlotCreator *plotCreator = [FGPlotCreator renderPlotImageWithPlotOptions:self.plotOptions fcsFile:self.fcsFile parentSubSet:nil parentSubSetCount:0];
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            self.finishedPlottingCompletionBlock(nil, plotCreator.plotImage, plotCreator.thumbImage);
        }];
    }
}



@end
