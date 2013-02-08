//
//  FGStyleController.m
//  Flow2Go
//
//  Created by Christian Hansen on 08/02/13.
//  Copyright (c) 2013 Christian Hansen. All rights reserved.
//

#import "FGStyleController.h"
#import "KGNoise.h"
#import "UIImage+Extensions.h"

@implementation FGStyleController

+ (void)applyAppearance
{
    [self styleNavigationBar];
}


+ (void)styleNavigationBar
{
    KGNoiseRadialGradientView *defaultNoiseView = [[KGNoiseRadialGradientView alloc] initWithFrame:CGRectMake(0, 0, 50, 44)];
    defaultNoiseView.backgroundColor            = [UIColor colorWithWhite:0.8032 alpha:1.000];
    defaultNoiseView.alternateBackgroundColor   = [UIColor colorWithWhite:0.8051 alpha:1.000];
    defaultNoiseView.noiseOpacity = 0.07;
    defaultNoiseView.noiseBlendMode = kCGBlendModeNormal;
    
    [[UINavigationBar appearance] setBackgroundImage:[UIImage imageWithView:defaultNoiseView] forBarMetrics:UIBarMetricsDefault];
    [[UINavigationBar appearance] setBackgroundImage:[UIImage imageWithView:defaultNoiseView] forBarMetrics:UIBarMetricsLandscapePhone];
    
    [[UINavigationBar appearance] setShadowImage:[UIImage imageNamed:@"ShadowImage-NavBar"]];
}

@end
