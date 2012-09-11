//
//  AddGateTableViewConroller.m
//  Flow2Go
//
//  Created by Christian Hansen on 11/09/12.
//  Copyright (c) 2012 Christian Hansen. All rights reserved.
//

#import "AddGateTableViewController.h"

@interface AddGateTableViewController ()

@end

@implementation AddGateTableViewController

#define POLYGON_GATE 0
#define SINGLE_RANGE_GATE 1
#define TRIPLE_RANGE_GATE 2
#define RECTANGLE_GATE 3
#define QUADRANT_GATE 4
#define ELLIPSE_GATE 5


- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    self.title = NSLocalizedString(@"Add Gate", nil);
    [self _loadValidGates];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"indexPath: %@",indexPath);
    switch (indexPath.row)
    {
        case POLYGON_GATE:
            [self.delegate addGateTableViewController:self didSelectGate:kGateTypePolygon];
            break;
            
        case SINGLE_RANGE_GATE:
            [self.delegate addGateTableViewController:self didSelectGate:kGateTypeSingleRange];
            break;
            
        case TRIPLE_RANGE_GATE:
            [self.delegate addGateTableViewController:self didSelectGate:kGateTypeTripleRange];
            break;
            
        case RECTANGLE_GATE:
            [self.delegate addGateTableViewController:self didSelectGate:kGateTypeRectangle];
            break;
            
        case QUADRANT_GATE:
            [self.delegate addGateTableViewController:self didSelectGate:kGateTypeQuadrant];
            break;
            
        case ELLIPSE_GATE:
            [self.delegate addGateTableViewController:self didSelectGate:kGateTypeEllipse];
            break;
            
        default:
            break;
    }
}


- (void)_loadValidGates
{
    NSArray *validGates = [self.delegate validGatesForCurrentPlot:self];
    NSLog(@"validGates: %@", validGates);
}

@end
