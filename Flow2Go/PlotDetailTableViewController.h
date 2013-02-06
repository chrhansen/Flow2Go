//
//  PlotDetailTableViewController.h
//  Flow2Go
//
//  Created by Christian Hansen on 30/08/12.
//  Copyright (c) 2012 Christian Hansen. All rights reserved.
//

#import <UIKit/UIKit.h>
@class FGPlot;
@class PlotDetailTableViewController;

@protocol PlotDetailTableViewControllerDelegate <NSObject>

- (void)didTapDeletePlot:(PlotDetailTableViewController *)sender;

@end

@interface PlotDetailTableViewController : UITableViewController

@property (nonatomic, weak) FGPlot *plot;
@property (nonatomic, weak) id<PlotDetailTableViewControllerDelegate> delegate;

@end
