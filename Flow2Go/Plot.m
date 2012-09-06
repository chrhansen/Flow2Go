//
//  Plot.m
//  Flow2Go
//
//  Created by Christian Hansen on 21/08/12.
//  Copyright (c) 2012 Christian Hansen. All rights reserved.
//

#import "Plot.h"
#import "Measurement.h"
#import "Analysis.h"

@implementation Plot

@dynamic xAxisType;
@dynamic yAxisType;
@dynamic countOfParentGates;

+ (Plot *)createPlotForAnalysis:(Analysis *)analysis parentNode:(Node *)parentNode
{
    Plot *newPlot = [Plot createInContext:analysis.managedObjectContext];
    newPlot.analysis = analysis;
    newPlot.parentNode = parentNode;
    
    Plot *parentPlot = (Plot *)parentNode.parentNode;
    newPlot.xParNumber = parentPlot.xParNumber;
    newPlot.yParNumber = parentPlot.yParNumber;
    if (parentPlot == nil)
    {
        newPlot.xParNumber = @1;
        newPlot.yParNumber = @2;
    }
    
    newPlot.dateCreated = NSDate.date;
    newPlot.name = [newPlot defaultPlotName];

    return newPlot;
}


- (NSString *)defaultPlotName
{
    NSString *sourceName = self.parentNode.name;
    if (self.parentNode.name == nil) sourceName = self.analysis.measurement.filename;

    return [NSString stringWithFormat:@"%@%@", NSLocalizedString(@"Plot of ", nil), sourceName];
}

- (NSArray *)childGatesForXPar:(NSInteger)xParNumber andYPar:(NSInteger)yParNumber
{
    NSMutableArray *relevantGates = NSMutableArray.array;
    for (Node *aGate in self.childNodes)
    {
        if ((aGate.xParNumber.integerValue == xParNumber && aGate.yParNumber.integerValue == yParNumber)
            || (aGate.yParNumber.integerValue == xParNumber && aGate.xParNumber.integerValue == yParNumber))
        {
            [relevantGates addObject:aGate];
        }
    }
    return relevantGates;
}


- (NSInteger)countOfParentGates
{
    Node *parentNode = self.parentNode;
    NSInteger countOfParentGates = 0;
    while (parentNode)
    {
        countOfParentGates += 1;
        parentNode = parentNode.parentNode.parentNode;
    }
    return countOfParentGates;
}

- (NSString *)plotSectionName
{
    NSString *parentCountString = [NSString stringWithFormat:@"%i", [self countOfParentGates]];
    return parentCountString;
}


@end
