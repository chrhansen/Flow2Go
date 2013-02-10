//
//  GraphPoint.m
//  Flow2Go
//
//  Created by Christian Hansen on 17/08/12.
//  Copyright (c) 2012 Christian Hansen. All rights reserved.
//

#import "FGGraphPoint.h"

@implementation FGGraphPoint

+ (FGGraphPoint *)pointWithX:(double)xValue andY:(double)yValue
{
    FGGraphPoint *newPoint = [FGGraphPoint.alloc init];
    newPoint.x = xValue;
    newPoint.y = yValue;
    
    return newPoint;
}


+ (NSArray *)switchXandYForGraphpoints:(NSArray *)vertices
{
    NSMutableArray *switchedArray = [NSMutableArray arrayWithCapacity:vertices.count];
    for (FGGraphPoint *aGraphPoint in vertices)
    {
        [switchedArray addObject:[FGGraphPoint pointWithX:aGraphPoint.y andY:aGraphPoint.x]];
    }
    return switchedArray;
}

- (void) encodeWithCoder:(NSCoder *)encoder
{
    //[super encodeWithCoder:encoder] as the first statement.
    
    [encoder encodeDouble:self.x forKey:@"x"];
    [encoder encodeDouble:self.y forKey:@"y"];
}

- (id) initWithCoder:(NSCoder*)decoder
{
    if (self = [super init]) {
        // If parent class also adopts NSCoding, replace [super init]
        // with [super initWithCoder:decoder] to properly initialize.
        
        // NOTE: Decoded objects are auto-released and must be retained
        self.x = [decoder decodeDoubleForKey:@"x"] ;
        self.y = [decoder decodeDoubleForKey:@"y"] ;
    }
    return self;
}


@end
