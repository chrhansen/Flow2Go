//
//  Gate.h
//  Flow2Go
//
//  Created by Christian Hansen on 14/08/12.
//  Copyright (c) 2012 Christian Hansen. All rights reserved.
//

#import <Foundation/Foundation.h>
@class FCSFile;
@class CPTXYPlotSpace;
@class Gate;

@interface GateCalculator : NSObject



+ (GateCalculator *)gateWithPath:(CGPathRef)path
                          inView:(UIView *)aView
                        onEvents:(FCSFile *)fcsFile
                          xParam:(NSUInteger)xPar
                          yParam:(NSUInteger)yPar
                     inPlotSpace:(CPTXYPlotSpace *)plotSpace;

+ (GateCalculator *)gateWithVertices:(NSArray *)vertices
                            onEvents:(FCSFile *)fcsFile
                              xParam:(NSUInteger)xPar
                              yParam:(NSUInteger)yPar;

+ (BOOL)eventInsideGateVertices:(NSArray *)vertices
                       onEvents:(FCSFile *)fcsFile
                        eventNo:(NSUInteger)eventNo
                         xParam:(NSUInteger)xPar
                         yParam:(NSUInteger)yPar;

+ (GateCalculator *)eventsIn:(FCSFile *)fcsFile insideGate:(Gate *)gate;

@property (nonatomic) NSUInteger numberOfCellsInside;
@property (nonatomic) NSUInteger *eventsInside;
@property (nonatomic, strong) NSArray *gateVertices;

@end
