//
//  AddGateTableViewConroller.h
//  Flow2Go
//
//  Created by Christian Hansen on 11/09/12.
//  Copyright (c) 2012 Christian Hansen. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol AddGateTableViewControllerDelegate <NSObject>

- (FGPlotType)addGateTableViewControllerCurrentPlotType:(id)sender;
- (void)addGateTableViewController:(id)sender didSelectGate:(FGGateType)gateType;

@end

@interface FGAddGateTableViewController : UITableViewController

@property (nonatomic, weak) id<AddGateTableViewControllerDelegate> delegate;


@end
