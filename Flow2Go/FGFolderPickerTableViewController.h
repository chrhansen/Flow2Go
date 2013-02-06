//
//  FGFolderPickerTableViewController.h
//  Flow2Go
//
//  Created by Christian Hansen on 06/02/13.
//  Copyright (c) 2013 Christian Hansen. All rights reserved.
//

#import <UIKit/UIKit.h>
@class FGFolder, FGFolderPickerTableViewController;

@protocol FGFolderPickerDelegate <NSObject>
@optional
- (void)folderPickerTableViewController:(FGFolderPickerTableViewController *)folderPickerTableViewController didPickFolder:(FGFolder *)folder;
@end

@interface FGFolderPickerTableViewController : UITableViewController
@property (nonatomic, weak) id<FGFolderPickerDelegate> delegate;
@end
