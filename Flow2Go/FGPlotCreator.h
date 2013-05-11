//
//  FGPlotCreator.h
//  Flow2Go
//
//  Created by Christian Hansen on 27/03/13.
//  Copyright (c) 2013 Christian Hansen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FGGraph.h"

@class FGFCSFile;

@interface FGPlotCreator : NSObject <CPTScatterPlotDataSource>

+ (FGPlotCreator *)renderPlotImageWithPlotOptions:(NSDictionary *)plotOptions
                                          fcsFile:(FGFCSFile *)fcsFile
                                     parentSubSet:(NSUInteger *)parentSubSet
                                parentSubSetCount:(NSUInteger)parentSubSetCount;


@property (nonatomic, strong) UIImage *plotImage;
@property (nonatomic, strong) UIImage *thumbImage;

#define DEFAULT_FRAME_IPAD   CGRectMake(0, 0, 750, 750)
#define DEFAULT_FRAME_IPHONE CGRectMake(0, 0, 320, 320)

@end
