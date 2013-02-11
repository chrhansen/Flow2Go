//
//  Gate.h
//  Flow2Go
//
//  Created by Christian Hansen on 14/08/12.
//  Copyright (c) 2012 Christian Hansen. All rights reserved.
//

#import <Foundation/Foundation.h>
@class FGFCSFile;
@class CPTXYPlotSpace;
@class FGGate;
@class FGPlot;

@interface FGGateCalculator : NSObject

+ (BOOL)eventInsideGateVertices:(NSArray *)vertices
                       onEvents:(FGFCSFile *)fcsFile
                        eventNo:(NSUInteger)eventNo
                         xParam:(NSUInteger)xPar
                         yParam:(NSUInteger)yPar;

+ (FGGateCalculator *)eventsInsideGateWithVertices:(NSArray *)vertices
                                          gateType:(FGGateType)gateType
                                           fcsFile:(FGFCSFile *)fcsFile
                                        insidePlot:(FGPlot *)plot
                                            subSet:(NSUInteger *)subSet
                                       subSetCount:(NSUInteger)subSetCount;

@property (nonatomic) NSUInteger numberOfCellsInside;
@property (nonatomic) NSUInteger *eventsInside;
@property (nonatomic) NSUInteger numberOfDensityPoints;
@property (nonatomic) FGDensityPoint *densityPoints;
@property (nonatomic, strong) NSArray *gateVertices;

@end
