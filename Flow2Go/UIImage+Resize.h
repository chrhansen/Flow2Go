//
//  UIImage+Resize.h
//  Flow2Go
//
//  Created by Christian Hansen on 06/03/13.
//  Copyright (c) 2013 Christian Hansen. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (Resize)

+ (void)resizeImage:(UIImage *)image toSize:(CGSize)size completion:(void (^)(UIImage *resizedImage))completion;

@end
