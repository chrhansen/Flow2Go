//
//  FGAnalysis+Management.m
//  Flow2Go
//
//  Created by Christian Hansen on 05/02/13.
//  Copyright (c) 2013 Christian Hansen. All rights reserved.
//

#import "FGAnalysis+Management.h"
#import "FGMeasurement+Management.h"
#import "FGPlot+Management.h"

@implementation FGAnalysis (Management)

+ (FGAnalysis *)createAnalysisForMeasurement:(FGMeasurement *)aMeasurement
{
    if (!aMeasurement) {
        return nil;
    }
    FGAnalysis *newAnalysis = [FGAnalysis createInContext:aMeasurement.managedObjectContext];
    
    newAnalysis.name = aMeasurement.filename.stringByDeletingPathExtension;
    newAnalysis.dateModified = NSDate.date;
    newAnalysis.measurement = aMeasurement;
    
    return newAnalysis;
}


- (FGPlot *)rootPlot
{
    for (FGPlot *aPlot in self.plots) {
        if (!aPlot.parentNode) {
            return aPlot;
        }
    }
    // No plots create root plot
    return [FGPlot createRootPlotForAnalysis:self];
}

@end
