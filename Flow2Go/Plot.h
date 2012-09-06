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

- (NSArray *)childGatesForXPar:(NSInteger)xParNumber andYPar:(NSInteger)yParNumber;

- (NSInteger)countOfParentGates;

@property (nonatomic, retain) NSNumber * xAxisType;
@property (nonatomic, retain) NSNumber * yAxisType;
@property (nonatomic, readonly) NSInteger countOfParentGates;
@property (nonatomic, readonly) NSString *plotSectionName;

@end
