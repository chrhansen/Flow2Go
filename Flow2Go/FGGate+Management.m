//
//  FGGate+Management.m
//  Flow2Go
//
//  Created by Christian Hansen on 05/02/13.
//  Copyright (c) 2013 Christian Hansen. All rights reserved.
//

#import "FGGate+Management.h"
#import "FGAnalysis+Management.h"
#import "FGKeyword.h"
#import "FGMeasurement+Management.h"
#import "FGPlot.h"

@implementation FGGate (Management)

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




+ (FGGate *)createChildGateInPlot:(FGPlot *)parentNode
                             type:(FGGateType)gateType
                         vertices:(NSArray *)vertices
{
    FGGate *newGate = [FGGate createInContext:parentNode.managedObjectContext];
    
    newGate.type = [NSNumber numberWithInteger:gateType];
    
    if (vertices) newGate.vertices = vertices;
    newGate.parentNode = parentNode;
    newGate.dateCreated = [NSDate date];
    newGate.analysis = parentNode.analysis;
    newGate.xParName = parentNode.xParName;
    newGate.yParName = parentNode.yParName;
    newGate.xParNumber = parentNode.xParNumber;
    newGate.yParNumber = parentNode.yParNumber;
    
    newGate.name = [newGate defaultGateName];
    
    return newGate;
}


- (NSString *)defaultGateName
{
    return [NSString stringWithFormat:@"%@%i", NSLocalizedString(@"Gate", nil), self.analysis.gates.count];
}


+ (BOOL)is1DGateType:(FGGateType)gateType
{
    switch (gateType) {
        case kGateTypeSingleRange:
        case kGateTypeTripleRange:
            return YES;
            break;
            
        default:
            return NO;
            break;
    }
}


+ (BOOL)is2DGateType:(FGGateType)gateType
{
    switch (gateType) {
        case kGateTypeEllipse:
        case kGateTypePolygon:
        case kGateTypeQuadrant:
        case kGateTypeRectangle:
            return YES;
            break;
            
        default:
            return NO;
            break;
    }
}

@end
