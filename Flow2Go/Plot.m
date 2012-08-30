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

+ (Plot *)createPlotForAnalysis:(Analysis *)analysis parentNode:(Node *)parentNode
{
    Plot *newPlot = [Plot createInContext:analysis.managedObjectContext];
    newPlot.analysis = analysis;
    newPlot.parentNode = parentNode;
    
    Plot *parentPlot = (Plot *)parentNode.parentNode;
    newPlot.xParNumber = parentPlot.xParNumber;
    newPlot.yParNumber = parentPlot.yParNumber;
    
    newPlot.name = [newPlot defaultPlotName];

    return newPlot;
}


- (NSString *)defaultPlotName
{
    return [NSString stringWithFormat:@"%@%@", NSLocalizedString(@"Plot of ", nil), self.parentNode.name];
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

@end
