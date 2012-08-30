//
//  GateTableViewController.h
//  Flow2Go
//
//  Created by Christian Hansen on 30/08/12.
//  Copyright (c) 2012 Christian Hansen. All rights reserved.
//

#import <UIKit/UIKit.h>
@class Gate;
@class GateTableViewController;

@protocol GateTableViewControllerDelegate <NSObject>

- (void)didTapNewPlot:(GateTableViewController *)sender;
- (void)didTapDeleteGate:(GateTableViewController *)sender;

@end

@interface GateTableViewController : UITableViewController

@property (nonatomic, weak) Gate *gate;
@property (nonatomic, weak) id<GateTableViewControllerDelegate> delegate;

@end
