//
//  FCSFile20Header.h
//  FCSViewer
//
//  Created by Christian Hansen on 2/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface FCSFile20Header : NSObject

+ (FCSFile20Header *)headerWithFCSFile:(NSString *)fcsFile;

@property (nonatomic, strong) NSString *text;
@property (nonatomic, strong) NSString *fcsVersion;
@property (nonatomic) NSRange textRange;
@property (nonatomic) NSRange dataRange;
@property (nonatomic) NSRange analysisRange;
@property (nonatomic) NSUInteger byteOrder;



@end
