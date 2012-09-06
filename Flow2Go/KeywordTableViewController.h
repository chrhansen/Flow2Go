//
//  KeywordTableViewController.h
//  Flow2Go
//
//  Created by Christian Hansen on 05/09/12.
//  Copyright (c) 2012 Christian Hansen. All rights reserved.
//

#import <UIKit/UIKit.h>
@class Measurement;

@interface KeywordTableViewController : UITableViewController <NSFetchedResultsControllerDelegate>

@property (nonatomic, strong) Measurement *measurement;

@end
