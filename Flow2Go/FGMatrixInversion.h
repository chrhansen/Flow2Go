//
//  FGMatrixInversion.h
//  Flow2Go
//
//  Created by Christian Hansen on 30/03/13.
//  Copyright (c) 2013 Christian Hansen. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FGMatrixInversion : NSObject

+ (BOOL)isIdentityMatrix:(double **)matrix order:(NSUInteger)order;
+ (double **)getInverseMatrix:(double **)a order:(NSUInteger)n;
+ (double *)multiplyMatrix:(double **)matrix byVector:(double *)vector order:(NSUInteger)order;
+ (double *)multiplyVector:(double *)vector byMatrix:(double **)matrix order:(NSUInteger)order;

@end
