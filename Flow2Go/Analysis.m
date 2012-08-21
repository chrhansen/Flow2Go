//
//  Analysis.m
//  Flow2Go
//
//  Created by Christian Hansen on 21/08/12.
//  Copyright (c) 2012 Christian Hansen. All rights reserved.
//

#import "Analysis.h"
#import "Gate.h"
#import "Measurement.h"
#import "Plot.h"


@implementation Analysis

@dynamic dateModified;
@dynamic dateViewed;
@dynamic name;
@dynamic measurement;
@dynamic plots;
@dynamic gates;

+ (Analysis *)createAnalysisForMeasurement:(Measurement *)aMeasurement
{
    Analysis *newAnalysis = [Analysis createInContext:aMeasurement.managedObjectContext];
    
    newAnalysis.name = aMeasurement.filename.stringByDeletingPathExtension;
    newAnalysis.dateModified = NSDate.date;
    newAnalysis.measurement = aMeasurement;
    
    return newAnalysis;
}


- (Plot *)createRootPlot
{
    if (self.plots.firstObject == nil)
    {
        [Plot createPlotForAnalysis:self parentNode:nil];
        [self.managedObjectContext save];
        
        return self.plots.firstObject;
    }
    return nil;
}

@end
