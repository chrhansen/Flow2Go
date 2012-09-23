//
//  GateTableViewController.m
//  Flow2Go
//
//  Created by Christian Hansen on 30/08/12.
//  Copyright (c) 2012 Christian Hansen. All rights reserved.
//

#import "GateTableViewController.h"
#import "Gate.h"
#import "Analysis.h"
#import "Measurement.h"
#import "NSString+UUID.h"

@interface GateTableViewController () <UITextFieldDelegate, UIActionSheetDelegate>
@property (weak, nonatomic) IBOutlet UITextField *gateName;
@property (weak, nonatomic) IBOutlet UITextField *gateCount;
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
    [self _addDoneButton];
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
    
    NSString *percentageString = [NSString percentageAsString:self.gate.cellCount.integerValue
                                                        ofAll:self.gate.analysis.measurement.countOfEvents.integerValue];
    self.gateCount.text = [NSString stringWithFormat:@"%@ (%@)", self.gate.cellCount, percentageString];
}


- (void)_addDoneButton
{
    [self.navigationItem setLeftBarButtonItem: [UIBarButtonItem.alloc initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(_doneTapped)] animated:YES];
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
        [self.gateName resignFirstResponder];
        if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad)
        {
            [self.navigationItem setLeftBarButtonItem:nil animated:NO];
        }
        else
        {
            [self _addDoneButton];
        }
    }
}

- (void)_doneTapped
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)_cancelTapped
{
    // consider deleting the gate and removing its path if user taps cancel directly after drawing the gate
    self.gateName.text = self.gate.name;
    [self setEditing:NO animated:YES];
}

- (IBAction)newPlotTapped:(id)sender
{
    [self.delegate didTapNewPlot:self];
}

- (IBAction)deleteGateTapped:(id)sender
{
    UIActionSheet *actionSheet = [UIActionSheet.alloc initWithTitle:NSLocalizedString(@"Delete Gate?", nil)
                                                           delegate:self
                                                  cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                             destructiveButtonTitle:NSLocalizedString(@"Delete", nil)
                                                  otherButtonTitles:nil];
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
