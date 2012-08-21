//
//  FCSFile20Data.h
//  FCSViewer
//
//  Created by Christian Hansen on 2/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FCSFile20Text.h"

@interface FCSFile20Data : NSObject

+ (FCSFile20Data *)dataWithFCSFile:(NSString *)fcsFile 
                           inRange:(NSRange)aRange 
                    noOfParameters:(NSUInteger)noOfPar 
                        noOfEvents:(NSUInteger)noOfEvents 
                andTextDescription:(FCSFile20Text *)fcsText;

//struct Event
//{
//	NSUInteger eventNo;
//};
//typedef struct Event Event;
//typedef Event* EventPtr;

struct Parameter
{
	NSUInteger value;
};
typedef struct Parameter Parameter;
typedef Parameter* ParameterPtr;


@property (nonatomic, strong) NSArray *events;
@property (nonatomic) NSUInteger **event;
@property (nonatomic) Parameter *parameter;
@property (nonatomic) NSUInteger *maxValues;

@end
