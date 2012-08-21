//
//  FCSHeader.h
//  Flow2Go
//
//  Created by Christian Hansen on 06/08/12.
//  Copyright (c) 2012 Christian Hansen. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FCSHeader : NSObject

@property (nonatomic) NSUInteger textBegin;
@property (nonatomic) NSUInteger textEnd;
@property (nonatomic) NSUInteger dataBegin;
@property (nonatomic) NSUInteger dataEnd;
@property (nonatomic) NSUInteger analysisBegin;
@property (nonatomic) NSUInteger analysisEnd;

@end
