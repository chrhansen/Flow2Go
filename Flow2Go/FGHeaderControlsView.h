//
//  FGTopHeaderView.h
//  Flow2Go
//
//  Created by Christian Hansen on 04/03/13.
//  Copyright (c) 2013 Christian Hansen. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FGHeaderControlsView : UICollectionReusableView

+ (CGSize)defaultSize;

@property (nonatomic, weak) IBOutlet UIButton *storeButton;

@end
