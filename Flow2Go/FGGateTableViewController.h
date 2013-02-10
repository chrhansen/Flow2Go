//
//  GateTableViewController.h
//  Flow2Go
//
//  Created by Christian Hansen on 30/08/12.
//  Copyright (c) 2012 Christian Hansen. All rights reserved.
//

#import <UIKit/UIKit.h>
@class FGGate;
@class FGGateTableViewController;

@protocol GateTableViewControllerDelegate <NSObject>

- (void)didTapNewPlot:(FGGateTableViewController *)sender;
- (void)didTapDeleteGate:(FGGateTableViewController *)sender;

@end

@interface FGGateTableViewController : UITableViewController

@property (nonatomic, weak) FGGate *gate;
@property (nonatomic, weak) id<GateTableViewControllerDelegate> delegate;

@end
