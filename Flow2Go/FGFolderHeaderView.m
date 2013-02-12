//
//  FGFolderHeaderView.m
//  Flow2Go
//
//  Created by Christian Hansen on 12/02/13.
//  Copyright (c) 2013 Christian Hansen. All rights reserved.
//

#import "FGFolderHeaderView.h"

@implementation FGFolderHeaderView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}


- (void)willMoveToSuperview:(UIView *)newSuperview
{
    [super willMoveToSuperview:newSuperview];
    [self.searchBar setBackgroundImage:[UIImage new]];
    [self.searchBar setTranslucent:YES];
}


/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
