//
//  FGAnalysisManager.h
//  Flow2Go
//
//  Created by Christian Hansen on 27/03/13.
//  Copyright (c) 2013 Christian Hansen. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FGAnalysis, FGMeasurement;

@interface FGAnalysisManager : NSObject

+ (FGAnalysisManager *)sharedInstance;

- (void)performAnalysis:(FGAnalysis *)analysis withCompletion:(void (^)(NSError *error))completion;
- (void)createRootPlotsForMeasurementsWithoutPlotsWithCompletion:(void (^)(void))completion;
- (void)createRootPlotsForMeasurements:(NSArray *)measurements;

@end
