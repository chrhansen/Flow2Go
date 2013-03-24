//
//  PlotDataCalculator.h
//  Flow2Go
//
//  Created by Christian Hansen on 29/08/12.
//  Copyright (c) 2012 Christian Hansen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FGPlot+Management.h"

@class FGFCSFile;

@interface FGPlotDataCalculator : NSObject

+ (FGPlotDataCalculator *)plotDataForFCSFile:(FGFCSFile *)fcsFile
                                 plotOptions:(NSDictionary *)plotOptions // see FGPlot header for options
                                      subset:(NSUInteger *)subset
                                 subsetCount:(NSUInteger)subsetCount;

- (void)cleanUpPlotData;

@property (nonatomic) NSUInteger numberOfPoints;
@property (nonatomic) FGDensityPoint *points;
@property (nonatomic) NSUInteger countForMaxBin;

@end
