//
//  PlotDataCalculator.h
//  Flow2Go
//
//  Created by Christian Hansen on 29/08/12.
//  Copyright (c) 2012 Christian Hansen. All rights reserved.
//

#import <Foundation/Foundation.h>
@class FCSFile;
@class Plot;

@interface PlotDataCalculator : NSObject

+ (PlotDataCalculator *)dotDataForFCSFile:(FCSFile *)fcsFile
                               insidePlot:(Plot *)plot
                                   subset:(NSUInteger *)subset
                              subsetCount:(NSUInteger)subsetCount;


+ (PlotDataCalculator *)densityDataForFCSFile:(FCSFile *)fcsFile
                                   insidePlot:(Plot *)plot
                                       subset:(NSUInteger *)subset
                                  subsetCount:(NSUInteger)subsetCount;


+ (PlotDataCalculator *)histogramForFCSFile:(FCSFile *)fcsFile
                                 insidePlot:(Plot *)plot
                                     subset:(NSUInteger *)subset
                                subsetCount:(NSUInteger)subsetCount;


+ (PlotDataCalculator *)plotDataForFCSFile:(FCSFile *)fcsFile
                                insidePlot:(Plot *)plot
                                    subset:(NSUInteger *)subset
                               subsetCount:(NSUInteger)subsetCount;


- (void)cleanUpPlotData;

@property (nonatomic) NSUInteger numberOfPoints;
@property (nonatomic) DensityPoint *points;
@property (nonatomic) NSUInteger countForMaxBin;

@end
