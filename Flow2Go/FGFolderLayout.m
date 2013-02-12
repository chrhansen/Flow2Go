//
//  FGFolderLayout.m
//  Flow2Go
//
//  Created by Christian Hansen on 08/02/13.
//  Copyright (c) 2013 Christian Hansen. All rights reserved.
//

#import "FGFolderLayout.h"
#import "FGEmblemView.h"

static NSString * const FGPhotoEmblemKind = @"Emblem";
@interface FGFolderLayout ()

@property (nonatomic, strong) NSDictionary *layoutInfo;

@end

@implementation FGFolderLayout

- (id)init
{
    self = [super init];
    if (self) {
        [self setup];
    }
    
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self) {
        [self setup];
    }
    
    return self;
}

- (void)setup
{
    self.itemSize = CGSizeMake(220.0f, 274.0f);
    self.minimumLineSpacing = 20.0f;
    self.minimumInteritemSpacing = 20.0f;
    self.sectionInset = UIEdgeInsetsMake(25, 25, 25, 25);
    self.headerReferenceSize = CGSizeMake(self.collectionView.bounds.size.width, 50.0f);
    [self registerClass:[FGEmblemView class] forDecorationViewOfKind:FGPhotoEmblemKind];
}

- (void)prepareLayout
{
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:0 inSection:0];    
    UICollectionViewLayoutAttributes *emblemAttributes = [UICollectionViewLayoutAttributes layoutAttributesForDecorationViewOfKind:FGPhotoEmblemKind withIndexPath:indexPath];
    emblemAttributes.frame = [self frameForEmblem];
    
    NSMutableDictionary *newLayoutInfo = [NSMutableDictionary dictionary];
    newLayoutInfo[FGPhotoEmblemKind] = @{indexPath: emblemAttributes};

    
    self.layoutInfo = newLayoutInfo;
}


- (CGSize)collectionViewContentSize
{
    CGSize size = [super collectionViewContentSize];
    CGFloat boundsHeight = self.collectionView.bounds.size.height;
    if (size.height <= boundsHeight) {
        size.height = boundsHeight + self.headerReferenceSize.height;
    }
    return size;
}


- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect {
    NSArray *attributes = [super layoutAttributesForElementsInRect:rect];
    NSMutableArray *newAttributes = [NSMutableArray arrayWithCapacity:attributes.count];
    for (UICollectionViewLayoutAttributes *attribute in attributes) {
        if (attribute.frame.origin.x + attribute.frame.size.width <= self.collectionViewContentSize.width) {
            [newAttributes addObject:attribute];
        }
    }
    [self.layoutInfo enumerateKeysAndObjectsUsingBlock:^(NSString *elementIdentifier, NSDictionary *elementsInfo, BOOL *stop) {
        [elementsInfo enumerateKeysAndObjectsUsingBlock:^(NSIndexPath *indexPath, UICollectionViewLayoutAttributes *attributes, BOOL *innerStop) {
            if (CGRectIntersectsRect(rect, attributes.frame)) {
                [newAttributes addObject:attributes];
            }
        }];
    }];
    return newAttributes;
}


- (UICollectionViewLayoutAttributes *)layoutAttributesForDecorationViewOfKind:(NSString*)decorationViewKind atIndexPath:(NSIndexPath *)indexPath
{
    return self.layoutInfo[FGPhotoEmblemKind][indexPath];
}


- (CGRect)frameForEmblem
{
    CGSize size = [FGEmblemView defaultSize];
    
    CGFloat originX = floorf((self.collectionView.bounds.size.width - size.width) * 0.5f);
    CGFloat originY = -size.height - 30.0f;
    
    return CGRectMake(originX, originY, size.width, size.height);
}

@end
