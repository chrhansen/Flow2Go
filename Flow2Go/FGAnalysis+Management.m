//
//  FGAnalysis+Management.m
//  Flow2Go
//
//  Created by Christian Hansen on 05/02/13.
//  Copyright (c) 2013 Christian Hansen. All rights reserved.
//

#import "FGAnalysis+Management.h"
#import "FGMeasurement+Management.h"

@implementation FGAnalysis (Management)

+ (FGAnalysis *)createAnalysisForMeasurement:(FGMeasurement *)aMeasurement
{
    FGAnalysis *newAnalysis = [FGAnalysis createInContext:aMeasurement.managedObjectContext];
    
    newAnalysis.name = aMeasurement.filename.stringByDeletingPathExtension;
    newAnalysis.dateModified = NSDate.date;
    newAnalysis.measurement = aMeasurement;
    
    return newAnalysis;
}

@end
