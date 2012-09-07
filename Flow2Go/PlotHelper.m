//
//  PlotHelper.m
//  Flow2Go
//
//  Created by Christian Hansen on 07/09/12.
//  Copyright (c) 2012 Christian Hansen. All rights reserved.
//

#import "PlotHelper.h"
#import "CPTPlotSymbol.h"
#import "CPTColor.h"
#import "CPTFill.h"

@implementation PlotHelper

+ (PlotHelper *)coloredPlotSymbols:(NSUInteger)colorLevels ofSize:(CGSize)symbolSize
{
    PlotHelper *newPlotHelper = PlotHelper.alloc.init;
    NSMutableArray *plotSymbols = NSMutableArray.array;
    
    float hue = 2.0f/3.0f;
    float increment = hue/((float)colorLevels - 1.0f);
    
    for (NSUInteger colorLevel = 0; colorLevel < colorLevels; colorLevel++)
    {
        if (hue < 0.0f) hue = 0.0f;
        
        UIColor *color = [UIColor colorWithHue:hue saturation:1.0 brightness:1.0 alpha:1.0];
        CPTColor *cptColor = [CPTColor colorWithCGColor:color.CGColor];

        CPTPlotSymbol *plotSymbol = [CPTPlotSymbol rectanglePlotSymbol];
        plotSymbol.fill = [CPTFill fillWithColor:cptColor];
        plotSymbol.lineStyle = nil;
        plotSymbol.size = symbolSize;
        
        [plotSymbols addObject:plotSymbol];
        hue -= increment;
    }
    
    newPlotHelper.plotSymbols = [NSArray arrayWithArray:plotSymbols];
    
    return newPlotHelper;
}

@end
