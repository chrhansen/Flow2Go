//
//  BHEmblemView.m
//  CollectionViewTutorial
//
//  Created by Bryan Hansen on 11/6/12.
//  Copyright (c) 2012 Bryan Hansen. All rights reserved.
//

#import "FGEmblemView.h"

static NSString * const BHEmblemViewImageName = @"Flow2Go_Garamond";

@implementation FGEmblemView

+ (CGSize)defaultSize
{
    return [UIImage imageNamed:BHEmblemViewImageName].size;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        UIImage *image = [UIImage imageNamed:BHEmblemViewImageName];
        UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
        imageView.frame = self.bounds;
        
        [self addSubview:imageView];
    }
    return self;
}

@end
