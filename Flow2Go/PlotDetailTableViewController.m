//
//  PlotDetailTableViewController.m
//  Flow2Go
//
//  Created by Christian Hansen on 30/08/12.
//  Copyright (c) 2012 Christian Hansen. All rights reserved.
//

#import "PlotDetailTableViewController.h"
#import "Plot.h"
#import "Gate.h"
#import "Analysis.h"
#import "Measurement.h"
#import "NSString+UUID.h"

@interface PlotDetailTableViewController () <UIActionSheetDelegate, UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *plotNameTextField;
@property (weak, nonatomic) IBOutlet UILabel *plotCount;
@property (weak, nonatomic) IBOutlet UIButton *deletePlotButton;
@property (weak, nonatomic) IBOutlet UILabel *parentGateName;

@end

@implementation PlotDetailTableViewController

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
    [self _enableDeleteButtonUnlessRootPlot:NO];
    [self _addDoneButton];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.title = self.plot.name;
    [self _configureLabels];
}

- (void)_addDoneButton
{
    [self.navigationItem setLeftBarButtonItem: [UIBarButtonItem.alloc initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(_doneTapped)] animated:YES];
}

- (void)_configureLabels
{
    Gate *parentGate = (Gate *)self.plot.parentNode;
    NSString *percentageString;
    if (!parentGate)
    {
        self.plotNameTextField.text = self.plot.analysis.measurement.filename;
        percentageString = [NSString percentageAsString:self.plot.analysis.measurement.countOfEvents.integerValue
                                                            ofAll:self.plot.analysis.measurement.countOfEvents.integerValue];
        self.plotCount.text = [NSString stringWithFormat:@"%@ (%@)", self.plot.analysis.measurement.countOfEvents, percentageString];
        self.parentGateName.text = NSLocalizedString(@"no parent", nil);
        self.parentGateName.alpha = 0.5;
    }
    else
    {
        self.plotNameTextField.text = self.plot.name;
        percentageString = [NSString percentageAsString:parentGate.cellCount.integerValue
                                                  ofAll:self.plot.analysis.measurement.countOfEvents.integerValue];
        self.plotCount.text = [NSString stringWithFormat:@"%@ (%@)", parentGate.cellCount, percentageString];
        self.parentGateName.text = parentGate.name;
    }
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)_enableDeleteButtonUnlessRootPlot:(BOOL)enable
{
    if (!self.plot.parentNode)
    {
        self.deletePlotButton.alpha = 0.5;
        self.deletePlotButton.enabled = NO;
        return;
    }
    self.deletePlotButton.enabled = enable;
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    [self.plotNameTextField setUserInteractionEnabled:editing];
    [self _enableDeleteButtonUnlessRootPlot:!editing];
    if (editing) {
        [self.editButtonItem setTitle:NSLocalizedString(@"Save", nil)];
        self.navigationItem.leftBarButtonItem = [UIBarButtonItem.alloc initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(_cancelTapped)];
        [self.plotNameTextField becomeFirstResponder];
    }
    else
    {
        self.plot.name = self.plotNameTextField.text;
        self.title = self.plot.name;
        [self.plot.managedObjectContext save];
        [self.navigationItem setLeftBarButtonItem:nil animated:YES];
        [self.plotNameTextField resignFirstResponder];
        if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
            [self.navigationItem setLeftBarButtonItem:nil animated:YES];
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
    self.plotNameTextField.text = self.plot.name;
    [self setEditing:NO animated:YES];
}


- (IBAction)deletePlotTapped:(id)sender
{
    UIActionSheet *actionSheet = [UIActionSheet.alloc initWithTitle:NSLocalizedString(@"Delete Plot?", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:NSLocalizedString(@"Delete", nil) otherButtonTitles:nil];
    [actionSheet showInView:self.tableView];
}

#pragma mark - Action Sheet Delegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == actionSheet.destructiveButtonIndex)
    {
        [self.delegate didTapDeletePlot:self];
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
