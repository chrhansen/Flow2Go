//
//  FGPlotCreator.h
//  Flow2Go
//
//  Created by Christian Hansen on 07/03/13.
//  Copyright (c) 2013 Christian Hansen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CorePlot-CocoaTouch.h"

@class FGPlot, FGMeasurement;

@interface FGPlotCreator : NSObject <CPTPlotDataSource, CPTScatterPlotDelegate, CPTScatterPlotDataSource, CPTPlotSpaceDelegate>

- (void)createRootPlotImageForMeasurement:(FGMeasurement *)measurement completion:(void (^)(UIImage *plotImage))completion;
+ (void)createRootPlotsForMeasurementsWithoutPlotsWithCompletion:(void (^)(void))completion;

@property (nonatomic, strong) FGPlot *plot;

@end
