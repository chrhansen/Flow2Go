//
//  FGAnalysis+Management.h
//  Flow2Go
//
//  Created by Christian Hansen on 05/02/13.
//  Copyright (c) 2013 Christian Hansen. All rights reserved.
//

#import "FGAnalysis.h"
@class FGMeasurement;
@interface FGAnalysis (Management)

+ (FGAnalysis *)createAnalysisForMeasurement:(FGMeasurement *)aMeasurement;

@property (nonatomic, readonly) FGPlot *rootPlot;

@end
