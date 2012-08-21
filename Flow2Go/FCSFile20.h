//
//  FCSFile20.h
//  FCSViewer
//
//  Created by Christian Hansen on 2/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FCSFile20Header.h"
#import "FCSFile20Text.h"
#import "FCSFile20Data.h"

@interface FCSFile20 : NSObject

+ (FCSFile20 *)fcsFileWithPath:(NSString *)path loadData:(BOOL)loadDataSection;



@property (nonatomic, strong) NSString *fileContent;
@property (nonatomic, strong) NSError *initError;
@property (nonatomic, strong) FCSFile20Header *header;
@property (nonatomic, strong) FCSFile20Text *text;
@property (nonatomic, strong) FCSFile20Data *data;
@property (nonatomic, readonly) NSUInteger numOfEvents;

@end
