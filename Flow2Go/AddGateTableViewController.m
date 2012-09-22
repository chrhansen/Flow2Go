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
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
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
    PlotType plotType = [self.delegate addGateTableViewControllerCurrentPlotType:self];
    NSLog(@"plotType: %i", plotType);
    
    if (plotType == kPlotTypeDot
        || plotType == kPlotTypeDensity)
    {
        for (NSInteger row = 0; row < [self.tableView numberOfRowsInSection:0]; ++row)
        {
            UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:0]];
            switch (row)
            {
                case POLYGON_GATE:
                case RECTANGLE_GATE:
                case QUADRANT_GATE:
                case ELLIPSE_GATE:
                    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
                    cell.userInteractionEnabled = YES;
                    cell.textLabel.textColor  = [UIColor blackColor];
                    break;
                    
                default:
                    cell.selectionStyle = UITableViewCellSelectionStyleNone;
                    cell.userInteractionEnabled = NO;
                    cell.textLabel.textColor  = [UIColor lightGrayColor];
                    break;
            }
        }
    }
    else if (plotType == kPlotTypeHistogram)
    {
        for (NSInteger row = 0; row < [self.tableView numberOfRowsInSection:0]; ++row)
        {
            UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:0]];
            switch (row)
            {
                case SINGLE_RANGE_GATE:
                case TRIPLE_RANGE_GATE:
                    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
                    cell.userInteractionEnabled = YES;
                    cell.textLabel.textColor  = [UIColor blackColor];
                    break;
                    
                default:
                    cell.selectionStyle = UITableViewCellSelectionStyleNone;
                    cell.userInteractionEnabled = NO;
                    cell.textLabel.textColor  = [UIColor lightGrayColor];
                    break;
            }
        }
    }
}

@end
