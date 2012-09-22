//
//  ContainerViewController.m
//  Flow2Go
//
//  Created by Christian Hansen on 20/09/12.
//  Copyright (c) 2012 Christian Hansen. All rights reserved.
//

#import "ContainerViewController.h"
#import "MeasurementCollectionViewController.h"
#import "AnalysisViewController.h"
#import <QuartzCore/QuartzCore.h>

@interface ContainerViewController ()

@property (nonatomic, strong) UIBarButtonItem *addToFolderBarButton;
@property (nonatomic, strong) MeasurementCollectionViewController *measurementViewController;
@property (nonatomic, strong) AnalysisViewController *analysisViewController;

@end

@implementation ContainerViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    [self _getReferencesToChildViewControllers];
    self.measurementViewController.delegate = self;
    self.measurementViewController.folder = self.folder;
    [self _configureBarButtonItemsForEditing:NO];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    [self _configureBarButtonItemsForEditing:editing];
    [self.measurementViewController setEditing:editing animated:animated];
    [self.analysisViewController setEditing:editing animated:animated];
}


- (void)_configureBarButtonItemsForEditing:(BOOL)editing
{
    if (editing)
    {
        UIBarButtonItem *shareButton = [UIBarButtonItem.alloc initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self.measurementViewController action:@selector(actionTapped:)];
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        [button setBackgroundImage:[UIImage imageNamed:@"delete.png"] forState:UIControlStateNormal];
        [button setTitle:NSLocalizedString(@"Delete", nil) forState:UIControlStateNormal];
        button.titleLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:12.0f];
        [button.layer setCornerRadius:4.0f];
        [button.layer setMasksToBounds:YES];
        [button.layer setBorderWidth:1.0f];
        [button.layer setBorderColor: [[UIColor grayColor] CGColor]];
        button.frame = CGRectMake(0.0, 100.0, 60.0, 30.0);
        [button addTarget:self.measurementViewController action:@selector(deleteTapped:) forControlEvents:UIControlEventTouchUpInside];
        UIBarButtonItem *deleteItem = [UIBarButtonItem.alloc initWithCustomView:button];
        deleteItem.enabled = NO;
        shareButton.enabled = NO;
        [self.navigationItem setLeftBarButtonItems:@[shareButton, deleteItem] animated:YES];
        
        self.addToFolderBarButton = [UIBarButtonItem.alloc initWithTitle:NSLocalizedString(@"Add...", nil) style:UIBarButtonItemStyleBordered target:self.measurementViewController action:@selector(addToTapped:)];
        [self.navigationItem setRightBarButtonItems:@[self.editButtonItem, self.addToFolderBarButton] animated:YES];
    }
    else
    {
        UIBarButtonItem *doneBarButton = [UIBarButtonItem.alloc initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self.measurementViewController action:@selector(doneTapped:)];
        UIBarButtonItem *addFilesBarButton = [UIBarButtonItem.alloc initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self.measurementViewController action:@selector(addFilesFromDropbox)];

        [self.navigationItem setLeftBarButtonItems:@[doneBarButton,addFilesBarButton] animated:YES];
        [self.navigationItem setRightBarButtonItems:@[self.editButtonItem] animated:YES];
        self.addToFolderBarButton = nil;
    }
}


- (void)doneTapped:(UIBarButtonItem *)doneButton
{
    [self dismissViewControllerAnimated:YES completion:nil];
    
    // prepare and dismiss child view controllers
}



- (void)_getReferencesToChildViewControllers
{
    for (UIViewController *aViewController in self.childViewControllers)
    {
        if ([aViewController isKindOfClass:MeasurementCollectionViewController.class])
        {
            self.measurementViewController = (MeasurementCollectionViewController *)aViewController;
        }
        else if ([aViewController isKindOfClass:AnalysisViewController.class])
        {
            self.analysisViewController = (AnalysisViewController *)aViewController;
        }
    }
}

#pragma mark - AnalysisPresentationProtocol
- (void)presentAnalysis:(Analysis *)analysis
{
    [self.analysisViewController showAnalysis:analysis];
}

@end
