//
//  DropboxViewController.h
//  Flow2Go
//
//  Created by Christian Hansen on 02/08/12.
//  Copyright (c) 2012 Christian Hansen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <DropboxSDK/DropboxSDK.h>
@class Folder;

@interface DropboxViewController : UITableViewController 

@property (nonatomic, strong) NSString *subPath;
@property (nonatomic, strong) Folder *folder;

@end
