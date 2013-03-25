//
//  UIImage+Extensions.m
//  Flow2Go
//
//  Created by Christian Hansen on 07/02/13.
//  Copyright (c) 2013 Christian Hansen. All rights reserved.
//

#import "UIImage+Extensions.h"
#import <QuartzCore/QuartzCore.h>
@implementation UIImage (Extensions)

+ (UIImage *)imageWithView:(UIView *)view
{
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, view.opaque, 0.0);
    [view.layer renderInContext:UIGraphicsGetCurrentContext()];
    
    UIImage * img = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return img;
}

+ (UIImage *)captureLayer:(CALayer *)layer flipImage:(BOOL)shouldFlipUpsideDown;
{
    UIGraphicsBeginImageContextWithOptions(layer.bounds.size, NO, 0.0f);
    [layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *screenImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    if (shouldFlipUpsideDown) {
        screenImage = [UIImage imageWithCGImage:screenImage.CGImage scale:screenImage.scale orientation:UIImageOrientationDownMirrored];
    }
    return screenImage;
}


+ (UIImage *)captureLayer:(CALayer *)layer
{
    return [self captureLayer:layer flipImage:NO];
}


- (UIImage *)overlayWith:(UIImage *)overlayImage {
    
	// size is taken from the background image
	UIGraphicsBeginImageContext(self.size);
    
	[self drawAtPoint:CGPointZero];
	[overlayImage drawAtPoint:CGPointZero];
    
	/*
     // If Image Artifacts appear, replace the "overlayImage drawAtPoint" , method with the following
     // Yes, it's a workaround, yes I filed a bug report
     CGRect imageRect = CGRectMake(0, 0, self.size.width, self.size.height);
     [overlayImage drawInRect:imageRect blendMode:kCGBlendModeOverlay alpha:0.999999999];
     */
    
	UIImage *combinedImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
    
	return combinedImage;
}


@end
