//
//  FGPlot+Management.h
//  Flow2Go
//
//  Created by Christian Hansen on 05/02/13.
//  Copyright (c) 2013 Christian Hansen. All rights reserved.
//

#import "FGPlot.h"

@interface FGPlot (Management)

+ (FGPlot *)createRootPlotForAnalysis:(FGAnalysis *)analysis;
+ (FGPlot *)createPlotForAnalysis:(FGAnalysis *)analysis parentNode:(FGNode *)parentNode;

- (NSArray *)childGatesForXPar:(NSInteger)xParNumber andYPar:(NSInteger)yParNumber;

- (NSInteger)countOfParentGates;

@end
