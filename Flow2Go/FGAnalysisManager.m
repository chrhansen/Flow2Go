//
//  FGAnalysisManager.m
//  Flow2Go
//
//  Created by Christian Hansen on 27/03/13.
//  Copyright (c) 2013 Christian Hansen. All rights reserved.
//

#import "FGAnalysisManager.h"
#import "FGFCSFile.h"
#import "FGAnalysis+Management.h"
#import "FGMeasurement+Management.h"
#import "FGPlot+Management.h"
#import "FGGate+Management.h"
#import "FGPlotCreator.h"
#import "FGGateCalculator.h"

@interface FGAnalysisManager ()

@property (nonatomic, strong) FGFCSFile *fcsFile;

@end



@implementation FGAnalysisManager

+ (FGAnalysisManager *)sharedInstance
{
    static FGAnalysisManager *_analysisManager = nil;
	if (_analysisManager == nil) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            _analysisManager = [FGAnalysisManager.alloc init];
        });
	}
    return _analysisManager;
}




- (void)createRootPlotsForMeasurementsWithoutPlotsWithCompletion:(void (^)(void))completion
{
    NSArray *allMeasurements = [FGMeasurement findAll];
    NSMutableArray *needPlots = [NSMutableArray array];
    for (FGMeasurement *aMeasurement in allMeasurements) {
        if (!aMeasurement.thumbImage) [needPlots addObject:aMeasurement];
    }
    [self createRootPlotsForMeasurements:needPlots];
    [[NSManagedObjectContext contextForCurrentThread] save:nil];
    if (completion) completion();
}


- (void)createRootPlotsForMeasurements:(NSArray *)measurements
{
    for (FGMeasurement *aMeasurement in measurements) {
        FGAnalysis *analysis = aMeasurement.analyses.firstObject;
        if (!analysis) analysis = [FGAnalysis createAnalysisForMeasurement:aMeasurement];
        FGPlot *rootPlot = analysis.rootPlot;
        NSError *error;
        FGFCSFile *fcsFile = [FGFCSFile fcsFileWithPath:aMeasurement.fullFilePath lastParsingSegment:FGParsingSegmentAnalysis error:&error];
        FGPlotCreator *plotCreator = [FGPlotCreator renderPlotImageWithPlotOptions:rootPlot.plotOptions
                                                                           fcsFile:fcsFile
                                                                      parentSubSet:nil
                                                                 parentSubSetCount:0];
        aMeasurement.thumbImage = plotCreator.thumbImage;
        rootPlot.image = plotCreator.plotImage;
    }
}



- (void)performAnalysis:(FGAnalysis *)analysis withCompletion:(void (^)(NSError *error))completion
{
    NSError *error;
    FGMeasurement *measurement = analysis.measurement;
    self.fcsFile = [FGFCSFile fcsFileWithPath:measurement.fullFilePath lastParsingSegment:FGParsingSegmentData error:&error];
    
    for (FGPlot *aPlot in analysis.plots) {
        FGGateCalculator *gateCalculator;
        if (aPlot.parentNode) {
            FGGate *parentGate = (FGGate *)aPlot.parentNode;
            gateCalculator = [self calculateSubSetForGate:parentGate];
            parentGate.cellCount = [NSNumber numberWithUnsignedInteger:gateCalculator.countOfEventsInside];
        }
        FGPlotCreator *plotCreator = [FGPlotCreator renderPlotImageWithPlotOptions:aPlot.plotOptions
                                                                           fcsFile:self.fcsFile
                                                                      parentSubSet:gateCalculator.eventsInside
                                                                 parentSubSetCount:gateCalculator.countOfEventsInside];
        aPlot.image = plotCreator.plotImage;
        if (!aPlot.parentNode) {
            // root plot
            measurement.thumbImage = plotCreator.thumbImage;
        }
    }
    
    [[NSManagedObjectContext contextForCurrentThread] saveToPersistentStoreAndWait];
    if (completion) completion(error);
}


- (FGGateCalculator *)calculateSubSetForGate:(FGGate *)gate
{
    // return nil of no parent gates or grandparent is not an FGGate
    FGNode *parentGate;
    if ([gate.parentNode.parentNode isKindOfClass:[FGGate class]]) {
        parentGate = gate.parentNode.parentNode;
    }
    
    NSMutableArray *parentGates = [NSMutableArray array];
    while (parentGate) {
        [parentGates addObject:parentGate];
        if ([parentGate.parentNode.parentNode isKindOfClass:[FGGate class]]) {
            parentGate = parentGate.parentNode.parentNode;
        }
    }
    FGGateCalculator *gateCalculator;
    while (parentGates.lastObject) {
        FGGate *gate   = parentGates.lastObject;
        gateCalculator = [FGGateCalculator eventsInsideGateWithXParameter:gate.xParName
                                                               yParameter:gate.yParName
                                                                 gateType:gate.type.integerValue
                                                                 vertices:gate.vertices
                                                                  fcsFile:self.fcsFile
                                                                   subSet:gateCalculator.eventsInside
                                                              subSetCount:gateCalculator.countOfEventsInside];
        [parentGates removeLastObject];
    }
    return gateCalculator;
}

















@end
