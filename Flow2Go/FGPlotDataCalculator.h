//
//  PlotDataCalculator.h
//  Flow2Go
//
//  Created by Christian Hansen on 29/08/12.
//  Copyright (c) 2012 Christian Hansen. All rights reserved.
//

#import <Foundation/Foundation.h>
@class FGFCSFile;
@class FGPlot;

@interface FGPlotDataCalculator : NSObject

+ (FGPlotDataCalculator *)plotDataForFCSFile:(FGFCSFile *)fcsFile
                                  insidePlot:(FGPlot *)plot
                                      subset:(NSUInteger *)subset
                                 subsetCount:(NSUInteger)subsetCount;

// For Thread-safe operations use the equivalent method below
+ (FGPlotDataCalculator *)plotDataForFCSFile:(FGFCSFile *)fcsFile
                                 plotOptions:(NSDictionary *)plotOptions
                                      subset:(NSUInteger *)subset
                                 subsetCount:(NSUInteger)subsetCount;

- (void)cleanUpPlotData;

@property (nonatomic) NSUInteger numberOfPoints;
@property (nonatomic) FGDensityPoint *points;
@property (nonatomic) NSUInteger countForMaxBin;

@end
