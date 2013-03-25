//
//  UIImage+Extensions.h
//  Flow2Go
//
//  Created by Christian Hansen on 07/02/13.
//  Copyright (c) 2013 Christian Hansen. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (Extensions)

+ (UIImage *)imageWithView:(UIView *)view;
+ (UIImage *)captureLayer:(CALayer *)layer flipImage:(BOOL)shouldFlipUpsideDown;
+ (UIImage *)captureLayer:(CALayer *)layer;
- (UIImage *)overlayWith:(UIImage *)overlayImage;

@end
