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
#import "FGFCSParserOperation.h"
#import "FGPendingOperations.h"
#import "FGPlotCreatorOperation.h"

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
            _analysisManager = [[FGAnalysisManager alloc] init];
        });
	}
    return _analysisManager;
}




- (void)createRootPlotsForMeasurementsWithoutPlotsWithCompletion:(void (^)(void))completion
{
    NSArray *downloadedMeasurements = [FGMeasurement findAllSortedBy:@"downloadDate" ascending:YES withPredicate:[NSPredicate predicateWithFormat:@"downloadState == %@", [NSNumber numberWithInteger:FGDownloadStateDownloaded]]];

    NSMutableArray *needPlots = [NSMutableArray array];
    for (FGMeasurement *aMeasurement in downloadedMeasurements) {
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
        [self _createRootPlotForMeasurement:aMeasurement];
    }
}


- (void)_createRootPlotForMeasurement:(FGMeasurement *)measurement
{
    FGFCSParserOperation *parserOperation = [[FGFCSParserOperation alloc] initWithFCSFileAtPath:measurement.fullFilePath lastParsingSegment:FGParsingSegmentData];
    [parserOperation setCompletionBlock:^(NSError *error, FGFCSFile *fcsFile) {
        if (!error) {
            FGPlot *rootPlot = [measurement.analyses.firstObject rootPlot];
            NSDictionary *plotOptions = rootPlot.plotOptions;
            
            FGPlotCreatorOperation *plotOperation = [[FGPlotCreatorOperation alloc] initWithFCSFile:fcsFile plotOptions:plotOptions];
            [plotOperation setCompletionBlock:^(NSError *error, UIImage *image, UIImage *thumbNail) {
                measurement.thumbImage = thumbNail;
                rootPlot.image = image;
                if (error) {
                    NSString *errorMessage = [NSString stringWithFormat:@"%@ %@", error.localizedDescription, measurement.filename];
                    [FGHUDMessage showHUDMessageOverNavigationBar:errorMessage];
                }
            }];
            [[FGPendingOperations sharedInstance].plotCreatorQueue addOperation:plotOperation];
        } else {
            NSString *errorMessage = [NSString stringWithFormat:@"%@ %@", error.localizedDescription, measurement.filename];
            [FGHUDMessage showHUDMessageOverNavigationBar:errorMessage];
        }
        
        [self performSelector:@selector(saveUpdates) onThread:[NSThread mainThread] withObject:nil waitUntilDone:NO modes:@[NSDefaultRunLoopMode]];
    }];
    [[FGPendingOperations sharedInstance].fcsParsingQueue addOperation:parserOperation];
}



- (void)performAnalysis:(FGAnalysis *)analysis withCompletion:(void (^)(NSError *error))completion
{
    NSError *error;
    FGMeasurement *measurement = analysis.measurement;
    self.fcsFile = [FGFCSFile fcsFileWithPath:measurement.fullFilePath lastParsingSegment:FGParsingSegmentData error:&error];
    NSOrderedSet *plots = analysis.plots;
    for (FGPlot *aPlot in plots) {
        NSLog(@"Plot: %@", aPlot.name);
        NSArray *gateDatas = [FGGate gatesAsData:aPlot.parentGates];
        FGGateCalculator *gateCalculator = [FGGateCalculator eventsInsideGatesWithDatas:gateDatas fcsFile:self.fcsFile];
        FGPlotCreator *plotCreator = [FGPlotCreator renderPlotImageWithPlotOptions:aPlot.plotOptions
                                                                           fcsFile:self.fcsFile
                                                                      parentSubSet:gateCalculator.eventsInside
                                                                 parentSubSetCount:gateCalculator.countOfEventsInside];
        aPlot.image = plotCreator.plotImage;
        if (!aPlot.parentNode) measurement.thumbImage = plotCreator.thumbImage;

        [self updateEventCountForGates:aPlot.childNodes.array
                       inSubPopulation:gateCalculator.eventsInside
                    subPopulationCount:gateCalculator.countOfEventsInside];
    }
    
    [[NSManagedObjectContext contextForCurrentThread] saveToPersistentStoreAndWait];
    if (completion) completion(error);
}


- (void)saveUpdates
{
    [[NSManagedObjectContext contextForCurrentThread] saveToPersistentStoreAndWait];
}


- (void)updateEventCountForGates:(NSArray *)gates inSubPopulation:(NSUInteger *)subPopulation subPopulationCount:(NSUInteger)subPopCount
{
    for (FGGate *gate in gates) {
        NSLog(@"  Gate: %@", gate.name);
        FGGateCalculator *gateCalculator = [FGGateCalculator eventsInsideGateWithData:gate.gateData
                                                                              fcsFile:self.fcsFile
                                                                               subSet:subPopulation
                                                                          subSetCount:subPopCount];
        gate.countOfEvents = [NSNumber numberWithUnsignedInteger:gateCalculator.countOfEventsInside];
    }
}

@end