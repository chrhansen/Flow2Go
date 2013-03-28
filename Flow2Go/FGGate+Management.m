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

const NSString *GateType       = @"GateType";
const NSString *GateName       = @"GateName";
const NSString *XParName       = @"XParName";
const NSString *YParName       = @"YParName";
const NSString *GateXParNumber = @"GateXParNumber";
const NSString *GateYParNumber = @"GateYParNumber";
const NSString *Vertices       = @"Vertices";

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

- (void)setParameterNames
{
    FGMeasurement *measurement = self.analysis.measurement;
    NSString *shortNameKey = [@"$P" stringByAppendingFormat:@"%iN", self.xParNumber.integerValue];
    FGKeyword *parNameKeyword = [measurement existingKeywordForKey:shortNameKey];
    self.xParName = parNameKeyword.value;
    shortNameKey = [@"$P" stringByAppendingFormat:@"%iN", self.yParNumber.integerValue];
    parNameKeyword = [measurement existingKeywordForKey:shortNameKey];
    self.yParName = parNameKeyword.value;
}


- (NSDictionary *)gateData
{
    if (!self.xParName || !self.yParName) {
        [self setParameterNames];
    }
    NSNumber *gateType   = self.type.copy;
    NSString *gateName   = self.name.copy;
    NSNumber *xParName   = self.xParName.copy;
    NSNumber *yParName   = self.yParName.copy;
    NSNumber *xParNumber = self.xParNumber.copy;
    NSNumber *yParNumber = self.yParNumber.copy;
    NSArray  *vertices   = [(NSArray *)self.vertices copy];
    
    return  @{GateType       : gateType,
              GateName       : gateName,
              XParName       : xParName,
              YParName       : yParName,
              GateXParNumber : xParNumber,
              GateYParNumber : yParNumber,
              Vertices       : vertices};
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

+ (NSError *)_obtainPermanentIDs:(NSArray *)managedObjects
{
    NSManagedObjectContext *context = [NSManagedObjectContext contextForCurrentThread];
    NSError *error;
    [context obtainPermanentIDsForObjects:managedObjects error:&error];
    return error;
}

+ (NSError *)deleteGates:(NSArray *)gatesToDelete
{
    NSError *permanentIDError = [self _obtainPermanentIDs:gatesToDelete];
    if (permanentIDError) {
        return permanentIDError;
    }
    NSMutableArray *objectIDs = [NSMutableArray array];
    for (NSManagedObject *anObject in gatesToDelete){
        [objectIDs addObject:anObject.objectID];
    }
    __block NSError *error;
    [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {
        for (NSManagedObjectID *anID in objectIDs) {
            FGGate *aGate = (FGGate *)[localContext existingObjectWithID:anID error:&error];
            if (error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSLog(@"Error: could not retrieve existing object from objectID: %@", error.localizedDescription);
                });
            }
            error = [self deleteGate:aGate];
            if (error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSLog(@"Error: could not delete measurement and/or measurement file: %@", error.localizedDescription);
                });
            }
        }
    }];
    return error;
}


+ (NSError *)deleteGate:(FGGate *)gate
{
    NSError *error = [self _obtainPermanentIDs:@[gate]];
    if (error) {
        return error;
    }
    [gate deleteInContext:gate.managedObjectContext];
    return error;
}

+ (NSArray *)gatesAsData:(NSArray *)gates
{
    NSMutableArray *dictionaries = [NSMutableArray arrayWithCapacity:gates.count];
    for (id aGate in gates) {
        if ([aGate isKindOfClass:FGGate.class]) {
            [dictionaries addObject:[(FGGate *)aGate gateData]];
        }
    }
    return dictionaries;
}


@end
