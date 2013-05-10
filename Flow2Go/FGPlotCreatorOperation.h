//
//  FGPlotCreatorOperation.h
//  Flow2Go
//
//  Created by Christian Hansen on 09/05/13.
//  Copyright (c) 2013 Christian Hansen. All rights reserved.
//

#import <Foundation/Foundation.h>
@class FGFCSFile;

@interface FGPlotCreatorOperation : NSOperation

- (id)initWithFCSFile:(FGFCSFile *)fcsFile plotOptions:(NSDictionary *)plotOptions;
- (void)setCompletionBlock:(void (^)(NSError *error, UIImage *image, UIImage *thumbNail))completion; //Operation Performed on main queue

@end
