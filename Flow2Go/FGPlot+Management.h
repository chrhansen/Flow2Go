//
//  FGPlot+Management.h
//  Flow2Go
//
//  Created by Christian Hansen on 05/02/13.
//  Copyright (c) 2013 Christian Hansen. All rights reserved.
//

#import "FGPlot.h"

// Plot Options dictionary keys
extern const NSString *PlotType;
extern const NSString *XAxisType;
extern const NSString *YAxisType;
extern const NSString *XParNumber;
extern const NSString *YParNumber;


@interface FGPlot (Management)

+ (FGPlot *)createRootPlotForAnalysis:(FGAnalysis *)analysis;
+ (FGPlot *)createPlotForAnalysis:(FGAnalysis *)analysis parentNode:(FGNode *)parentNode;
- (NSArray *)parentGateNames;
- (NSArray *)childGatesForXPar:(NSInteger)xParNumber andYPar:(NSInteger)yParNumber;
- (NSInteger)countOfParentGates;
- (NSArray *)parentGates;

@property (nonatomic, readonly, copy) NSDictionary *plotOptions;

@end
