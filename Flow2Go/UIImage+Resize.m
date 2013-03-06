//
//  UIImage+Resize.m
//  Flow2Go
//
//  Created by Christian Hansen on 06/03/13.
//  Copyright (c) 2013 Christian Hansen. All rights reserved.
//

#import "UIImage+Resize.h"

@implementation UIImage (Resize)

+ (void)resizeImage:(UIImage *)image toSize:(CGSize)size completion:(void (^)(UIImage *resizedImage))completion
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        UIImage *resizedImage = [self scaleImage:image toSize:size];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) completion(resizedImage);
        });
    });
}


+ (UIImage *)scaleImage:(UIImage*)image toSize:(CGSize)newSize
{
    CGSize scaledSize = newSize;
    float scaleFactor = 1.0;
    if( image.size.width > image.size.height ) {
        scaleFactor = image.size.width / image.size.height;
        scaledSize.width = newSize.width;
        scaledSize.height = newSize.height / scaleFactor;
    }
    else {
        scaleFactor = image.size.height / image.size.width;
        scaledSize.height = newSize.height;
        scaledSize.width = newSize.width / scaleFactor;
    }
    
    UIGraphicsBeginImageContextWithOptions( scaledSize, NO, 0.0 );
    CGRect scaledImageRect = CGRectMake( 0.0, 0.0, scaledSize.width, scaledSize.height );
    [image drawInRect:scaledImageRect];
    UIImage* scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return scaledImage;
}




//- (UIImage *)captureLayer:(CALayer *)layer
//{
//    CGSize newSize = CGSizeMake(300, 300);
//    CGFloat ratio = newSize.width / layer.bounds.size.width;
//    CGAffineTransform transform = CGAffineTransformIdentity;
//    transform = CGAffineTransformScale(transform, ratio, ratio);
//
//    UIGraphicsBeginImageContextWithOptions(newSize, NO, 1.0f);
//    CGContextRef context = UIGraphicsGetCurrentContext();
//    CGContextSaveGState(context);
//    CGContextConcatCTM(context, transform);
//    [layer renderInContext:context];
//    UIImage *screenImage = UIGraphicsGetImageFromCurrentImageContext();
//    CGContextRestoreGState(context);
//    UIGraphicsEndImageContext();
////    UIGraphicsBeginImageContextWithOptions(layer.bounds.size, NO, 1.0f);
////    [layer renderInContext:UIGraphicsGetCurrentContext()];
////    UIImage *screenImage = UIGraphicsGetImageFromCurrentImageContext();
////    UIGraphicsEndImageContext();
//    return screenImage;
//}


@end
