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

+ (FGPlotDataCalculator *)dotDataForFCSFile:(FGFCSFile *)fcsFile
                                 insidePlot:(FGPlot *)plot
                                     subset:(NSUInteger *)subset
                                subsetCount:(NSUInteger)subsetCount;


+ (FGPlotDataCalculator *)densityDataForFCSFile:(FGFCSFile *)fcsFile
                                     insidePlot:(FGPlot *)plot
                                         subset:(NSUInteger *)subset
                                    subsetCount:(NSUInteger)subsetCount;


+ (FGPlotDataCalculator *)histogramForFCSFile:(FGFCSFile *)fcsFile
                                   insidePlot:(FGPlot *)plot
                                       subset:(NSUInteger *)subset
                                  subsetCount:(NSUInteger)subsetCount;


+ (FGPlotDataCalculator *)plotDataForFCSFile:(FGFCSFile *)fcsFile
                                  insidePlot:(FGPlot *)plot
                                      subset:(NSUInteger *)subset
                                 subsetCount:(NSUInteger)subsetCount;


- (void)cleanUpPlotData;

@property (nonatomic) NSUInteger numberOfPoints;
@property (nonatomic) FGDensityPoint *points;
@property (nonatomic) NSUInteger countForMaxBin;

@end
