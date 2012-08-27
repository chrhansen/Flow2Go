//
//  Plot.h
//  Flow2Go
//
//  Created by Christian Hansen on 21/08/12.
//  Copyright (c) 2012 Christian Hansen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "Node.h"


@interface Plot : Node

+ (Plot *)createPlotForAnalysis:(Analysis *)analysis parentNode:(Node *)parentNode;

+ (Plot *)createChildPlotForGate:(Node *)parentNode
                       xAxisType:(AxisType)xAxisType
                       yAxisType:(AxisType)yAxisType
                       xAxisName:(NSString *)xAxisName
                       yAxisName:(NSString *)yAxisName;

- (NSArray *)childGatesForXPar:(NSInteger)xParNumber andYPar:(NSInteger)yParNumber;

@property (nonatomic, retain) NSNumber * xAxisType;
@property (nonatomic, retain) NSNumber * yAxisType;

@end
