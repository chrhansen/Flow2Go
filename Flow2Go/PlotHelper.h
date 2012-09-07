//
//  PlotHelper.h
//  Flow2Go
//
//  Created by Christian Hansen on 07/09/12.
//  Copyright (c) 2012 Christian Hansen. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PlotHelper : NSObject

+ (PlotHelper *)coloredPlotSymbols:(NSUInteger)colorLevels ofSize:(CGSize)symbolSize;

@property (nonatomic, strong) NSArray *plotSymbols;

@end
