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
    return CGSizeMake(320, 50);
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor redColor];
        UISearchBar *searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 200, 50)];
        UIButton *button = [UIButton buttonWithType:UIButtonTypeContactAdd];
        button.center = CGPointMake(250.0f, 25.0f);
        [self addSubview:searchBar];
        [self addSubview:button];
    }
    return self;
}
@end
