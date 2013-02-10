//
//  GraphPoint.h
//  Flow2Go
//
//  Created by Christian Hansen on 17/08/12.
//  Copyright (c) 2012 Christian Hansen. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FGGraphPoint : NSObject

+ (FGGraphPoint *)pointWithX:(double)xValue andY:(double)yValue;

+ (NSArray *)switchXandYForGraphpoints:(NSArray *)vertices;

@property (nonatomic) double x;
@property (nonatomic) double y;

@end
