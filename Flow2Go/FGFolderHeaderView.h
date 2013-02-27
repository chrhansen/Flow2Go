//
//  FGFolderHeaderView.h
//  Flow2Go
//
//  Created by Christian Hansen on 12/02/13.
//  Copyright (c) 2013 Christian Hansen. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FGFolderHeaderView : UICollectionReusableView

@property (nonatomic, strong) IBOutlet UISearchBar *searchBar;
@property (nonatomic, weak) IBOutlet UIButton *storeButton;
@property (nonatomic, weak) IBOutlet UIButton *feedbackButton;
@property (nonatomic, weak) IBOutlet UISegmentedControl *layoutSegmentedControl;

@end
