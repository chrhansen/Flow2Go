//
//  FGErrorReporter.m
//  Flow2Go
//
//  Created by Christian Hansen on 07/04/13.
//  Copyright (c) 2013 Christian Hansen. All rights reserved.
//

#import "FGHUDMessage.h"
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    
@implementation FGHUDMessage

+ (void)showHUDMessage:(NSString *)message inView:(UIView *)view
{
    MBProgressHUD *hud = [self textHUDWithMessage:message inView:view];
	[hud hide:YES afterDelay:ERROR_MESSAGE_DURATION];
}


+ (void)showHUDMessageOverNavigationBar:(NSString *)message
{
    UIWindow* window = [UIApplication sharedApplication].keyWindow;
    if (!window) {
        window = [[UIApplication sharedApplication].windows objectAtIndex:0];
    }
    MBProgressHUD *hud = [self textHUDWithMessage:message inView:window];
    hud.yOffset = - window.bounds.size.height / 2.0f + 60.0f;
	[hud hide:YES afterDelay:ERROR_MESSAGE_DURATION];
}


+ (MBProgressHUD *)textHUDWithMessage:(NSString *)message inView:(UIView *)view
{
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:view animated:YES];
	hud.mode = MBProgressHUDModeText;
	hud.labelText = message;
	hud.removeFromSuperViewOnHide = YES;
    hud.opacity = 0.5f;
    hud.userInteractionEnabled = NO;
    [hud hide:YES afterDelay:HELPER_MESSAGE_DURATION];
    return hud;
}


@end
