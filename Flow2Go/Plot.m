//
//  Plot.m
//  Flow2Go
//
//  Created by Christian Hansen on 21/08/12.
//  Copyright (c) 2012 Christian Hansen. All rights reserved.
//

#import "Plot.h"
#import "Analysis.h"

@implementation Plot

@dynamic xAxisType;
@dynamic yAxisType;

+ (Plot *)createPlotForAnalysis:(Analysis *)analysis

{
    Plot *newPlot = [Plot createInContext:analysis.managedObjectContext];
    newPlot.analysis = analysis;
    
    return newPlot;
}

+ (Plot *)createChildPlotForGate:(Node *)parentNode
                       xAxisType:(AxisType)xAxisType
                       yAxisType:(AxisType)yAxisType
                       xAxisName:(NSString *)xAxisName
                       yAxisName:(NSString *)yAxisName
{
    Plot *newPlot;
    
    if (parentNode == nil)
    {
        // Root node
        newPlot = [Plot createInContext:NSManagedObjectContext.MR_defaultContext];
    }
    else
    {
        newPlot = [Plot createInContext:parentNode.managedObjectContext];
    }
    
    newPlot.xAxisType = [NSNumber numberWithInteger:xAxisType];
    newPlot.yAxisType = [NSNumber numberWithInteger:yAxisType];
    
    newPlot.parentNode = parentNode;
    
    newPlot.xParName = xAxisName;
    if (!yAxisName)
    {
        yAxisName = @"";
    }
    newPlot.yParName = yAxisName;
    
    return newPlot;
}

@end
