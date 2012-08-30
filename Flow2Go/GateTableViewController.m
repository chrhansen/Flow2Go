//
//  GateTableViewController.m
//  Flow2Go
//
//  Created by Christian Hansen on 30/08/12.
//  Copyright (c) 2012 Christian Hansen. All rights reserved.
//

#import "GateTableViewController.h"
#import "Gate.h"

@interface GateTableViewController () <UITextFieldDelegate, UIActionSheetDelegate>
@property (weak, nonatomic) IBOutlet UITextField *gateName;
@property (weak, nonatomic) IBOutlet UILabel *gateCount;
@property (weak, nonatomic) IBOutlet UIButton *createNewPlotButton;
@property (weak, nonatomic) IBOutlet UIButton *deleteGateButton;

@end

@implementation GateTableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self _configureLabels];
}

- (void)_configureLabels
{
    self.gateName.text = self.gate.name;
    self.gateCount.text = self.gate.cellCount.stringValue;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    self.createNewPlotButton.enabled = !editing;
    self.deleteGateButton.enabled = !editing;
    [self.gateName setUserInteractionEnabled:editing];
    
    if (editing) {
            self.navigationItem.leftBarButtonItem = [UIBarButtonItem.alloc initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(_cancelTapped)];
        [self.gateName becomeFirstResponder];
    }
    else
    {
        self.gate.name = self.gateName.text;
        [self.gate.managedObjectContext save];
        [self.navigationItem setLeftBarButtonItem:nil animated:YES];
        [self.gateName resignFirstResponder];
    }
}


- (void)_cancelTapped
{
    self.gateName.text = self.gate.name;
    [self setEditing:NO animated:YES];
}

- (IBAction)newGateTapped:(id)sender
{
    [self.delegate didTapNewPlot:self];
}

- (IBAction)deleteGateTapped:(id)sender
{
    UIActionSheet *actionSheet = [UIActionSheet.alloc initWithTitle:NSLocalizedString(@"Delete Gate?", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:NSLocalizedString(@"Delete", nil) otherButtonTitles:nil];
    [actionSheet showInView:self.tableView];
}

#pragma mark - Action Sheet Delegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == actionSheet.destructiveButtonIndex)
    {
        [self.delegate didTapDeleteGate:self];
    }
}

#pragma mark - Text Field delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    return YES;
}

#pragma mark - TableView delegates
- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

@end
