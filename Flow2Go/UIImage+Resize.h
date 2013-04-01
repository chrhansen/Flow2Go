//
//  UIImage+Resize.h
//  Flow2Go
//
//  Created by Christian Hansen on 06/03/13.
//  Copyright (c) 2013 Christian Hansen. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (Resize)

+ (void)scaleImage:(UIImage *)image toSize:(CGSize)size completion:(void (^)(UIImage *scaledImage))completion; // completion block is called on main queue
+ (UIImage *)scaleImage:(UIImage*)image toSize:(CGSize)newSize;

@end
