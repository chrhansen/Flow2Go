//
//  DensityPlotData.h
//  Flow2Go
//
//  Created by Christian Hansen on 29/08/12.
//  Copyright (c) 2012 Christian Hansen. All rights reserved.
//

#import <Foundation/Foundation.h>
@class FCSFile;
@class Plot;

@interface DensityPlotData : NSObject

+ (DensityPlotData *)densityForPointsygonInFcsFile:(FCSFile *)fcsFile
                                        insidePlot:(Plot *)plot
                                            subSet:(NSUInteger *)subSet
                                       subSetCount:(NSUInteger)subSetCount;

@property (nonatomic) NSUInteger numberOfPoints;
@property (nonatomic) DensityPoint *points;
@property (nonatomic) NSUInteger countForMaxBin;


@end
