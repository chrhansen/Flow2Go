//
//  FGFolderLayout.m
//  Flow2Go
//
//  Created by Christian Hansen on 08/02/13.
//  Copyright (c) 2013 Christian Hansen. All rights reserved.
//

#import "FGFolderLayout.h"
#import "FGEmblemView.h"
#import "FGHeaderControlsView.h"

static NSString * const FGEmblemKind = @"Emblem";
static NSString * const FGHeaderControlsKind = @"HeaderControlsKind";
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
    if (IS_IPAD) {
        self.sectionInset = UIEdgeInsetsMake(25, 25, 25, 25);
    } else {
        self.sectionInset = UIEdgeInsetsMake(5, 5, 5, 5);
    }
    self.itemSize = CGSizeMake(260.0f, 120.0f);
    self.minimumLineSpacing = 5.0f;
    self.minimumInteritemSpacing = 5.0f;
    self.headerReferenceSize = CGSizeMake(self.collectionView.bounds.size.width, 50.0f);
    [self registerClass:[FGEmblemView class]         forDecorationViewOfKind:FGEmblemKind];
    [self registerClass:[FGHeaderControlsView class] forDecorationViewOfKind:FGHeaderControlsKind];
}

- (void)prepareLayout
{
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:0 inSection:0];
    //Emblem
    UICollectionViewLayoutAttributes *emblemAttributes = [UICollectionViewLayoutAttributes layoutAttributesForDecorationViewOfKind:FGEmblemKind withIndexPath:indexPath];
    emblemAttributes.frame = [self frameForDecorationViewOfKind:FGEmblemKind];
    //Header Controls
    UICollectionViewLayoutAttributes *headerControlsAttributes = [UICollectionViewLayoutAttributes layoutAttributesForDecorationViewOfKind:FGHeaderControlsKind withIndexPath:indexPath];
    headerControlsAttributes.frame = [self frameForDecorationViewOfKind:FGHeaderControlsKind];

    
    NSMutableDictionary *newLayoutInfo = [NSMutableDictionary dictionary];
    newLayoutInfo[FGEmblemKind] = @{indexPath: emblemAttributes};
    newLayoutInfo[FGHeaderControlsKind] = @{indexPath: headerControlsAttributes};

    
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
    return self.layoutInfo[FGEmblemKind][indexPath];
}


- (CGRect)frameForDecorationViewOfKind:(NSString *)kind
{
    if ([kind isEqualToString:FGEmblemKind]) {
        CGSize size = [FGEmblemView defaultSize];
        
        CGFloat originX = floorf((self.collectionView.bounds.size.width - size.width) * 0.5f);
        CGFloat originY = -size.height - 55.0f;
        
        return CGRectMake(originX, originY, size.width, size.height);
    } else if ([kind isEqualToString:FGHeaderControlsKind]) {
        CGSize size = [FGHeaderControlsView defaultSize];
        
        CGFloat originX = floorf((self.collectionView.bounds.size.width - size.width) * 0.5f);
        CGFloat originY = 0.0f;
        
        return CGRectMake(originX, originY, size.width, size.height);
    }
    return CGRectZero;
}

@end
