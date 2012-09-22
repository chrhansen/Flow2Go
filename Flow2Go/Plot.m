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
#import "Gate.h"

@implementation Plot

@dynamic xAxisType;
@dynamic yAxisType;
@dynamic plotType;
@dynamic countOfParentGates;
@dynamic plotSectionName;

+ (Plot *)createPlotForAnalysis:(Analysis *)analysis parentNode:(Node *)parentNode
{
    Plot *newPlot = [Plot createInContext:analysis.managedObjectContext];
    newPlot.analysis = analysis;
    newPlot.parentNode = parentNode;
    
    Plot *parentPlot = (Plot *)parentNode.parentNode;
    newPlot.xParNumber = parentPlot.xParNumber;
    newPlot.yParNumber = parentPlot.yParNumber;
    newPlot.plotType = parentPlot.plotType;
    if (parentPlot == nil)
    {
        newPlot.xParNumber = @1;
        newPlot.yParNumber = @2;
        newPlot.plotType = [NSNumber numberWithInteger:kPlotTypeDensity];
    }
    newPlot.plotSectionName = [NSString stringWithFormat:@"%i", [newPlot countOfParentGates]];
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
    PlotType plotType = self.plotType.integerValue;
    
    for (Gate *aGate in self.childNodes)
    {
        if ((aGate.xParNumber.integerValue == xParNumber && aGate.yParNumber.integerValue == yParNumber)
            || (aGate.yParNumber.integerValue == xParNumber && aGate.xParNumber.integerValue == yParNumber))
        {
            GateType gateType = aGate.type.integerValue;
            
            if ([Gate is1DGateType:gateType]
                && plotType == kPlotTypeHistogram)
            {
                [relevantGates addObject:aGate];
            }
            else if ([Gate is2DGateType:gateType]
                     && (plotType == kPlotTypeDot || plotType == kPlotTypeDensity))
            {
                [relevantGates addObject:aGate];
            }
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
