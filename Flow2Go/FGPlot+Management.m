//
//  FGPlot+Management.m
//  Flow2Go
//
//  Created by Christian Hansen on 05/02/13.
//  Copyright (c) 2013 Christian Hansen. All rights reserved.
//

#import "FGPlot+Management.h"
#import "FGAnalysis+Management.h"
#import "FGKeyword.h"
#import "FGMeasurement+Management.h"
#import "FGGate+Management.h"

@implementation FGPlot (Management)

+ (FGPlot *)createRootPlotForAnalysis:(FGAnalysis *)analysis
{
    return [self createPlotForAnalysis:analysis parentNode:nil];
}

+ (FGPlot *)createPlotForAnalysis:(FGAnalysis *)analysis parentNode:(FGNode *)parentNode
{
    if (!analysis) return nil;
    
    FGPlot *newPlot = [FGPlot createInContext:analysis.managedObjectContext];
    newPlot.analysis = analysis;
    newPlot.parentNode = parentNode;
    
    FGPlot *parentPlot = (FGPlot *)parentNode.parentNode;
    newPlot.xParNumber = parentPlot.xParNumber;
    newPlot.yParNumber = parentPlot.yParNumber;
    newPlot.plotType = parentPlot.plotType;
    if (parentPlot == nil) {
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
    return [NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"Plot of", nil), sourceName];
}

- (NSArray *)childGatesForXPar:(NSInteger)xParNumber andYPar:(NSInteger)yParNumber
{
    NSMutableArray *relevantGates = NSMutableArray.array;
    FGPlotType plotType = self.plotType.integerValue;
    
    for (FGGate *aGate in self.childNodes) {
        if ((aGate.xParNumber.integerValue == xParNumber && aGate.yParNumber.integerValue == yParNumber)
            || (aGate.yParNumber.integerValue == xParNumber && aGate.xParNumber.integerValue == yParNumber)) {
            FGGateType gateType = aGate.type.integerValue;
            
            if ([FGGate is1DGateType:gateType]
                && plotType == kPlotTypeHistogram) {
                [relevantGates addObject:aGate];
            } else if ([FGGate is2DGateType:gateType]
                     && (plotType == kPlotTypeDot || plotType == kPlotTypeDensity)) {
                [relevantGates addObject:aGate];
            }
        }
    }
    return relevantGates;
}


- (NSInteger)countOfParentGates
{
    FGNode *parentNode = self.parentNode;
    NSInteger countOfParentGates = 0;
    while (parentNode) {
        countOfParentGates += 1;
        parentNode = parentNode.parentNode.parentNode;
    }
    return countOfParentGates;
}

#pragma mark - Image getters/setters


- (void)setImage:(UIImage*)image
{
    [self willChangeValueForKey:@"image"];
    
    NSData *data = UIImagePNGRepresentation(image);
    //[self setImage:data];
    [self setPrimitiveValue:data forKey:@"image"];
    [self didChangeValueForKey:@"image"];
}

- (UIImage*)image
{
    [self willAccessValueForKey:@"image"];
    UIImage *image = [UIImage imageWithData:[self primitiveValueForKey:@"image"]];
    [self didAccessValueForKey:@"image"];
    return image;
}




- (void)setXParNumber:(NSNumber *)newXParNumber
{
    if (newXParNumber.integerValue != self.xParNumber.integerValue)
    {
        [self willChangeValueForKey:@"xParNumber"];
        [self setPrimitiveValue:newXParNumber forKey:@"xParNumber"];
        [self didChangeValueForKey:@"xParNumber"];
        
        NSString *shortNameKey = [@"$P" stringByAppendingFormat:@"%iN", newXParNumber.integerValue];
        FGKeyword *parNameKeyword = [self.analysis.measurement existingKeywordForKey:shortNameKey];
        self.xParName = parNameKeyword.value;
    }
}


- (void)setYParNumber:(NSNumber *)newYParNumber
{
    if (newYParNumber.integerValue != self.yParNumber.integerValue)
    {
        [self willChangeValueForKey:@"yParNumber"];
        [self setPrimitiveValue:newYParNumber forKey:@"yParNumber"];
        [self didChangeValueForKey:@"yParNumber"];
        
        NSString *shortNameKey = [@"$P" stringByAppendingFormat:@"%iN", newYParNumber.integerValue];
        FGKeyword *parNameKeyword = [self.analysis.measurement existingKeywordForKey:shortNameKey];
        self.yParName = parNameKeyword.value;
    }
}

@end
