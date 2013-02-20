//
//  FGAnalysisLayout.m
//  Flow2Go
//
//  Created by Christian Hansen on 20/02/13.
//  Copyright (c) 2013 Christian Hansen. All rights reserved.
//

#import "FGAnalysisLayout.h"

@implementation FGAnalysisLayout

- (UICollectionViewLayoutAttributes *)initialLayoutAttributesForAppearingItemAtIndexPath:(NSIndexPath *)itemIndexPath
{
    UICollectionViewLayoutAttributes* attributes = [super initialLayoutAttributesForAppearingItemAtIndexPath:itemIndexPath];
    attributes.alpha = 0.0;
    CGSize size = [self collectionView].frame.size;
    attributes.center = CGPointMake(size.width / 2.0, size.height / 2.0);
    return attributes;
}


- (UICollectionViewLayoutAttributes *)finalLayoutAttributesForDisappearingItemAtIndexPath:(NSIndexPath *)itemIndexPath
{
    UICollectionViewLayoutAttributes* attributes = [super initialLayoutAttributesForAppearingItemAtIndexPath:itemIndexPath];
    attributes.alpha = 0.0;
    CGSize size = [self collectionView].frame.size;
    attributes.center = CGPointMake(size.width / 2.0, size.height / 2.0);
    
    return attributes;
}


@end
