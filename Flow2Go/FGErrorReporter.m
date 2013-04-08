//
//  FGErrorReporter.m
//  Flow2Go
//
//  Created by Christian Hansen on 07/04/13.
//  Copyright (c) 2013 Christian Hansen. All rights reserved.
//

#import "FGErrorReporter.h"
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    
@implementation FGErrorReporter

+ (void)showErrorMess:(NSString *)message inView:(UIView *)view
{
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:view animated:YES];
	
	// Configure for text only and offset down
	hud.mode = MBProgressHUDModeText;
	hud.labelText = message;
	hud.removeFromSuperViewOnHide = YES;
	[hud hide:YES afterDelay:3];
}

@end
