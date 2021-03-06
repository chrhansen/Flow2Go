//
//  FGTopHeaderView.m
//  Flow2Go
//
//  Created by Christian Hansen on 04/03/13.
//  Copyright (c) 2013 Christian Hansen. All rights reserved.
//

#import "FGHeaderControlsView.h"

@implementation FGHeaderControlsView

+ (CGSize)defaultSize
{
    if (IS_IPAD) {
        return CGSizeMake(500, 50);
    } else {
        return CGSizeMake(320, 100);
    }
}



- (void)willMoveToSuperview:(UIView *)newSuperview
{
    [super willMoveToSuperview:newSuperview];
    [[NSNotificationCenter defaultCenter] postNotificationName:FGHeaderControlsWillAppearNotification
                                                        object:nil
                                                      userInfo:@{@"storeButton": self.storeButton}];
}

@end
