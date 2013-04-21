//
//  FGErrorReporter.h
//  Flow2Go
//
//  Created by Christian Hansen on 07/04/13.
//  Copyright (c) 2013 Christian Hansen. All rights reserved.
//

#import <Foundation/Foundation.h>

#define HELPER_MESSAGE_DURATION 5.0  // seconds
#define ERROR_MESSAGE_DURATION 3.0  // seconds

@interface FGHUDMessage : NSObject

+ (void)showHUDMessage:(NSString *)message inView:(UIView *)view;
+ (void)showHUDMessageOverNavigationBar:(NSString *)message;
+ (MBProgressHUD *)textHUDWithMessage:(NSString *)message inView:(UIView *)view;

@end
