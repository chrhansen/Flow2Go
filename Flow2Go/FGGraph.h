//
//  FGGraph.h
//  Flow2Go
//
//  Created by Christian Hansen on 01/04/13.
//  Copyright (c) 2013 Christian Hansen. All rights reserved.
//

#import "CorePlot-CocoaTouch.h"

@protocol FGGraphDataSource <CPTScatterPlotDataSource>

- (NSInteger)countForHistogramMaxValue;

@end

@interface FGGraph : CPTXYGraph

@property (nonatomic, weak) id<FGGraphDataSource> dataSource;

- (id)initWithFrame:(CGRect)newFrame themeNamed:(NSString *)themeName;

- (void)updateGraphWithPlotOptions:(NSDictionary *)plotOptions;
- (void)adjustPlotRangeToFitXRange:(FGRange)xMinMaxRange yRange:(FGRange)yMinMaxRange plotType:(FGPlotType)plotType;

@end


// From CPTTheme class:
// kCPTDarkGradientTheme; ///< A graph theme with dark gray gradient backgrounds and light gray lines.
// kCPTPlainBlackTheme;   ///< A graph theme with black backgrounds and white lines.
// kCPTPlainWhiteTheme;   ///< A graph theme with white backgrounds and black lines.
// kCPTSlateTheme;        ///< A graph theme with colors that match the default iPhone navigation bar, toolbar buttons, and table views.
// kCPTStocksTheme;       ///< A graph theme with a gradient background and white lines.
