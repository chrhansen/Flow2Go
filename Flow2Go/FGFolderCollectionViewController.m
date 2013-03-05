//
//  FolderCollectionViewController.m
//  Flow2Go
//
//  Created by Christian Hansen on 19/09/12.
//  Copyright (c) 2012 Christian Hansen. All rights reserved.
//

#import "FGFolderCollectionViewController.h"
#import "FGFolder+Management.h"
#import "FGDownloadManager.h"
#import "UIBarButtonItem+Customview.h"
#import "FGFolderCell.h"
#import "FGMeasurementCell.h"
#import "KGNoise.h"
#import "FGFolderLayout.h"
#import "FGStackedLayout.h"
#import "FGMeasurement+Management.h"
#import "NSString+_Format.h"
#import "NSDate+Formatting.h"
#import "ATConnect.h"
#import "ATSurveys.h"
#import "FGAnalysisViewController.h"
#import "FGAnalysis+Management.h"
#import "MSNavigationPaneViewController.h"
#import "FGHeaderControlsView.h"

@interface FGFolderCollectionViewController () <UIActionSheetDelegate, FGDownloadManagerProgressDelegate, UISearchBarDelegate>

@property (nonatomic, strong) NSMutableArray *editItems;
@property (nonatomic, strong) UIBarButtonItem *leftBarButtonItem;
@property (nonatomic, strong) NSMutableArray *objectChanges;
@property (nonatomic, strong) NSMutableArray *sectionChanges;
@property (nonatomic) CGFloat verticalContentOffsetFraction;

@end

@implementation FGFolderCollectionViewController

- (void)awakeFromNib
{
    [super awakeFromNib];
    _objectChanges = [NSMutableArray array];
    _sectionChanges = [NSMutableArray array];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self _configureBarButtonItemsForEditing:NO];
    [self _addNoiseBackground];
    [self _observings];
    [self.analysisViewController addNavigationPaneBarbuttonWithTarget:self selector:@selector(navigationPaneBarButtonItemTapped:)];
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self _updateVisibleCells];
    [FGDownloadManager.sharedInstance setProgressDelegate:self];
    [self _updatePaneViewControllerOpenWidthForInterfaceOrientation:self.interfaceOrientation];
    [self _updateFrameToFitUnderPaneViewController];
    [self.collectionView.collectionViewLayout prepareLayout];
    [self.collectionView.collectionViewLayout invalidateLayout];
    [self.collectionView setContentOffset:CGPointMake(0, [FGHeaderControlsView defaultSize].height)];
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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
    if (!editing) [self _discardEditItems];
    [self _updateVisibleCells];
}


- (void)_addNoiseBackground
{
    KGNoiseRadialGradientView *collectionNoiseView = [[KGNoiseRadialGradientView alloc] initWithFrame:self.collectionView.bounds];
    collectionNoiseView.backgroundColor            = [UIColor colorWithWhite:0.7032 alpha:1.000];
    collectionNoiseView.alternateBackgroundColor   = [UIColor colorWithWhite:0.7051 alpha:1.000];
    collectionNoiseView.noiseOpacity               = 0.07;
    collectionNoiseView.noiseBlendMode             = kCGBlendModeNormal;
    self.collectionView.backgroundView             = collectionNoiseView;
}


- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    self.verticalContentOffsetFraction = self.collectionView.contentOffset.y / self.collectionView.contentSize.height;
    [self _updatePaneViewControllerOpenWidthForInterfaceOrientation:toInterfaceOrientation];
}


- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    if (self.verticalContentOffsetFraction > 0.0f && self.verticalContentOffsetFraction < 1.0f) {
        CGFloat verticalContentOffset = self.collectionView.contentSize.height * self.verticalContentOffsetFraction;
        self.collectionView.contentOffset = CGPointMake(0, verticalContentOffset);
    } else {
        self.collectionView.contentOffset = CGPointMake(0, [FGHeaderControlsView defaultSize].height);
    }
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [self _updateFrameToFitUnderPaneViewController];
}


- (void)navigationPaneBarButtonItemTapped:(id)sender
{
    [self.navigationPaneViewController setPaneState:MSNavigationPaneStateOpen animated:YES completion:nil];
}


#pragma mark - Editing state
- (void)_configureBarButtonItemsForEditing:(BOOL)editing
{
    if (editing) {
        UIBarButtonItem *uploadButton = [UIBarButtonItem barButtonWithImage:[UIImage imageNamed:@"0108"] style:UIBarButtonItemStylePlain target:self action:@selector(exportToCloudTapped:)];
        UIBarButtonItem *deleteItem = [UIBarButtonItem barButtonWithImage:[UIImage imageNamed:@"0210"] style:UIBarButtonItemStylePlain target:self action:@selector(deleteTapped:)];
        uploadButton.enabled = NO;
        deleteItem.enabled = NO;
        [self.navigationItem setLeftBarButtonItems:@[uploadButton, deleteItem] animated:YES];
        [self.navigationItem setRightBarButtonItems:@[self.editButtonItem] animated:YES];
    } else {
        UIBarButtonItem *importButton = [UIBarButtonItem barButtonWithImage:[UIImage imageNamed:@"0107"] style:UIBarButtonItemStylePlain target:self action:@selector(importFromCloudTapped:)];
        [self.navigationItem setLeftBarButtonItems:@[importButton] animated:YES];
        [self.navigationItem setRightBarButtonItems:@[self.editButtonItem] animated:YES];
    }
}

#pragma mark Import/Export
- (void)importFromCloudTapped:(id)sender
{
    [self performSegueWithIdentifier:@"Show Dropbox" sender:sender];
}


- (void)exportToCloudTapped:(id)sender
{
    NSLog(@"exportToCloudTapped");
}


- (void)togglePaneTapped:(UIBarButtonItem *)doneButton
{
    MSNavigationPaneState paneState = MSNavigationPaneStateOpen;
    if (self.navigationPaneViewController.paneState == MSNavigationPaneStateOpen) {
        paneState = MSNavigationPaneStateClosed;
    }
    [self.navigationPaneViewController setPaneState:paneState animated:YES completion:nil];
}


- (void)_updateFrameToFitUnderPaneViewController
{
    CGRect newFrame = CGRectMake(0, 0, self.navigationPaneViewController.openStateRevealWidth, self.navigationController.view.bounds.size.height);
    self.navigationController.view.frame = newFrame;
}

- (void)_updatePaneViewControllerOpenWidthForInterfaceOrientation:(UIInterfaceOrientation)orientation
{
    if (self.interfaceOrientation == orientation) {
        self.navigationPaneViewController.openStateRevealWidth = self.view.bounds.size.width - PANE_COVER_WIDTH;
    } else {
        CGFloat revealWidth = self.view.bounds.size.height - PANE_COVER_WIDTH;
        if (![[UIApplication sharedApplication] isStatusBarHidden]) revealWidth += 20.0f;
        if (!self.navigationController.navigationBar.isHidden) revealWidth += self.navigationController.navigationBar.frame.size.height;
        self.navigationPaneViewController.openStateRevealWidth = revealWidth;
    }
    [self.navigationPaneViewController setPaneState:self.navigationPaneViewController.paneState animated:YES completion:nil];
}

- (void)deleteTapped:(UIButton *)deleteButton
{
    NSString *deleteString;
    if (self.editItems.count == 1) {
        deleteString = NSLocalizedString(@"Are you sure you want to delete the selected folder?", nil);
    } else {
        deleteString = NSLocalizedString(@"Are you sure you want to delete the selected folders?", nil);
    }
    UIActionSheet *actionSheet = [UIActionSheet.alloc initWithTitle:deleteString
                                                           delegate:self
                                                  cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                             destructiveButtonTitle:NSLocalizedString(@"Delete", nil)
                                                  otherButtonTitles: nil];
    [actionSheet showFromRect:deleteButton.frame inView:self.navigationController.navigationBar animated:YES];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (!buttonIndex == actionSheet.cancelButtonIndex) {
        NSArray *deleteItems = [self.editItems copy];
        [self.editItems removeAllObjects];
        [self _toggleBarButtonStateOnChangedEditItems];
        [FGMeasurement deleteMeasurements:deleteItems];
    }
    [self setEditing:NO animated:YES];
}


- (void)_updateCheckmarkVisibilityForCell:(UICollectionViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    id anObject = [self.fetchedResultsController objectAtIndexPath:indexPath];
    [(FGMeasurementCell *)cell checkMarkImageView].hidden = ![self.editItems containsObject:anObject];
}


- (void)_togglePresenceInEditItems:(id)anObject
{
    if (!self.editItems) self.editItems = NSMutableArray.array;
    if ([self.editItems containsObject:anObject]) {
        [self.editItems removeObject:anObject];
    } else {
        [self.editItems addObject:anObject];
    }
}

- (void)_toggleBarButtonStateOnChangedEditItems
{
    [self.navigationItem.leftBarButtonItems[0] setEnabled:(self.editItems.count > 0)];
    [self.navigationItem.leftBarButtonItems[1] setEnabled:(self.editItems.count > 0)];
}

- (void)_discardEditItems
{
    [self.editItems removeAllObjects];
    self.editItems = nil;
    [self _updateVisibleCells];
}

- (void)_updateVisibleCells
{
    for (NSIndexPath *indexPath in self.collectionView.indexPathsForVisibleItems) {
        FGFolderCell *cell = (FGFolderCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
        [self configureCell:cell atIndexPath:indexPath];
    }
}

#pragma mark - Header Button actions

- (IBAction)storeButtonTapped:(id)sender
{
    [self performSegueWithIdentifier:@"Show Store" sender:sender];
}


- (IBAction)feedbackButtonTapped:(id)sender
{
    ATConnect *connection = [ATConnect sharedConnection];
    [connection presentFeedbackControllerFromViewController:self];
}


- (IBAction)layoutControlTapped:(UISegmentedControl *)layoutControl
{
    if (layoutControl.selectedSegmentIndex == 0 && ![self.collectionView.collectionViewLayout isKindOfClass:[FGStackedLayout class]]) {
        FGStackedLayout *stackedLayout = [[FGStackedLayout alloc] init];
        [self.collectionView setCollectionViewLayout:stackedLayout animated:YES];
    } else if (layoutControl.selectedSegmentIndex == 1 && ![self.collectionView.collectionViewLayout isKindOfClass:[FGFolderLayout class]]) {
        FGFolderLayout *folderLayout = [[FGFolderLayout alloc] init];
        [self.collectionView setCollectionViewLayout:folderLayout animated:YES];
    }
}

#pragma mark Apptentive
#pragma mark - Apptentive
- (void)_observings
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(surveyBecameAvailable:) name:ATSurveyNewSurveyAvailableNotification object:nil];
    [ATSurveys checkForAvailableSurveys];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(headerControlsWillAppear:) name:FGHeaderControlsWillAppearNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDidSaveNotification:) name:NSManagedObjectContextDidSaveNotification object:nil];
}

- (void)surveyBecameAvailable:(NSNotification *)notification
{
    [ATSurveys presentSurveyControllerFromViewController:self];
}



#pragma mark UISearchBar delegate
- (void)headerControlsWillAppear:(NSNotification *)notification
{
    UISearchBar *searchBar = notification.userInfo[@"searchBar"];
    searchBar.delegate = self;
    UISegmentedControl *segmentedControl = notification.userInfo[@"segmentedControl"];
    segmentedControl.selectedSegmentIndex = [self.collectionView.collectionViewLayout isKindOfClass:[FGStackedLayout class]] ? 0 : 1;
}


- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    NSLog(@"search text: %@", searchText);
}


#define FILENAME_CHARACTER_COUNT 30

- (void)configureCell:(UICollectionViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    FGMeasurement *measurement = [self.fetchedResultsController objectAtIndexPath:indexPath];
    FGMeasurementCell *measurementCell = (FGMeasurementCell *)cell;
    measurementCell.fileNameLabel.text = [measurement.filename fitToLength:FILENAME_CHARACTER_COUNT];
    measurementCell.dateLabel.hidden = (measurement.isDownloaded) ? NO : YES;
    measurementCell.dateLabel.text = [measurement.downloadDate readableDate];
    measurementCell.infoButton.enabled = measurement.isDownloaded;
    measurementCell.eventCountLabel.hidden = (measurement.isDownloaded) ? NO : YES;
    measurementCell.eventCountLabel.text = (measurement.isDownloaded) ? measurement.countOfEvents.stringValue : @"-";
    measurementCell.infoButton.hidden = self.isEditing;
    if (!self.isEditing) measurementCell.checkMarkImageView.hidden = YES;
}


#pragma mark - Download Manager progress delegate
- (void)downloadManager:(FGDownloadManager *)downloadManager beganDownloadingMeasurement:(FGMeasurement *)measurement
{
    [self _updateDownloadProgressViewForMeasurement:measurement progress:0.0f];
}

- (void)downloadManager:(FGDownloadManager *)downloadManager loadProgress:(CGFloat)progress forMeasurement:(FGMeasurement *)measurement
{
    [self _updateDownloadProgressViewForMeasurement:measurement progress:progress];
}

- (void)downloadManager:(FGDownloadManager *)downloadManager finishedDownloadingMeasurement:(FGMeasurement *)measurement
{
    [self _updateDownloadProgressViewForMeasurement:measurement progress:1.0f];
    [self.collectionView layoutSubviews];
}

- (void)downloadManager:(FGDownloadManager *)downloadManager failedDownloadingMeasurement:(FGMeasurement *)measurement
{
    //TODO: figure out how to configure cell when a download failed
    //    [self _updateDownloadProgressView:downloadManager forMeasurement:measurement];
    NSLog(@"failedDownloadingMeasurement: %@", measurement);
}


- (void)_updateDownloadProgressViewForMeasurement:(FGMeasurement *)measurement progress:(CGFloat)progress
{
    FGMeasurementCell *downloadCell = (FGMeasurementCell *)[self.collectionView cellForItemAtIndexPath:[self.fetchedResultsController indexPathForObject:measurement]];
    downloadCell.progressView.progress = progress;
    downloadCell.progressView.hidden = (progress == 1.0f) ? YES : NO;
}



#pragma mark - Collection View Data source
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return self.fetchedResultsController.sections.count;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    id <NSFetchedResultsSectionInfo> sectionInfo = self.fetchedResultsController.sections[section];
    return sectionInfo.numberOfObjects;
}


- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Measurement Cell" forIndexPath:indexPath];
    [self configureCell:cell atIndexPath:indexPath];
    return cell;
}


- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0 && [kind isEqualToString:UICollectionElementKindSectionHeader]) {
//        FGFolderHeaderView *headerView = (FGFolderHeaderView *)[collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"Folder Header" forIndexPath:indexPath];
//        headerView.searchBar.delegate = self;
//        [headerView.storeButton addTarget:self action:@selector(storeButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
//        [headerView.feedbackButton addTarget:self action:@selector(feedbackButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
//        [headerView.layoutSegmentedControl addTarget:self action:@selector(layoutControlTapped:) forControlEvents:UIControlEventValueChanged];
//        return headerView;
    }
    return nil;
}

#pragma mark - UICollectionView delegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    id object = [self.fetchedResultsController objectAtIndexPath:indexPath];
    UICollectionViewCell *cell = [self.collectionView cellForItemAtIndexPath:indexPath];
    switch (self.isEditing) {
        case YES:
            [self _togglePresenceInEditItems:object];
            [self _updateCheckmarkVisibilityForCell:cell atIndexPath:indexPath];
            [self _toggleBarButtonStateOnChangedEditItems];
            break;
            
        case NO:
            [self _presentMeasurement:(FGMeasurement *)object];
            break;
    }
}


- (void)_presentMeasurement:(FGMeasurement *)aMeasurement
{
    if (aMeasurement.isDownloaded == NO) return;
    
    FGAnalysis *analysis = aMeasurement.analyses.lastObject;
    if (analysis == nil) {
        analysis = [FGAnalysis createAnalysisForMeasurement:aMeasurement];
        NSError *error;
        if(![analysis.managedObjectContext obtainPermanentIDsForObjects:@[analysis] error:&error]) NSLog(@"Error obtaining perm ID: %@", error.localizedDescription);
    }
    [self.analysisViewController showAnalysis:analysis];
}


#pragma mark - Fetched results controller
- (NSFetchedResultsController *)fetchedResultsController
{
    if (_fetchedResultsController != nil) {
        return _fetchedResultsController;
    }
    _fetchedResultsController = [FGMeasurement fetchAllGroupedBy:@"folder.name"
                                                   withPredicate:nil
                                                        sortedBy:@"filename"
                                                       ascending:YES
                                                        delegate:self
                                                       inContext:[NSManagedObjectContext defaultContext]];
    return _fetchedResultsController;
}




















































#pragma mark - NSManagedContext
- (void)handleDidSaveNotification:(NSNotification *)notification
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
}


#pragma mark Fetched Results Controller Delegate methods
- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
    NSMutableDictionary *change = [NSMutableDictionary new];
    switch(type) {
        case NSFetchedResultsChangeInsert:
            change[@(type)] = @(sectionIndex);
            break;
        case NSFetchedResultsChangeDelete:
            change[@(type)] = @(sectionIndex);
            break;
    }
    [_sectionChanges addObject:change];
}


- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
    NSMutableDictionary *change = [NSMutableDictionary new];
    switch(type) {
        case NSFetchedResultsChangeInsert:
            change[@(type)] = newIndexPath;
            break;
        case NSFetchedResultsChangeDelete:
            change[@(type)] = indexPath;
            break;
        case NSFetchedResultsChangeUpdate:
            change[@(type)] = indexPath;
            break;
        case NSFetchedResultsChangeMove:
            change[@(type)] = @[indexPath, newIndexPath];
            break;
    }
    [_objectChanges addObject:change];
}


- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self _performOutstandingCollectionViewUpdates];
}


- (void)_performOutstandingCollectionViewUpdates
{
    if (self.navigationController.visibleViewController != self)
    {
        [self.collectionView reloadData];
    }
    else
    {
        if ([_sectionChanges count] > 0)
        {
            [self.collectionView performBatchUpdates:^{
                
                for (NSDictionary *change in _sectionChanges)
                {
                    [change enumerateKeysAndObjectsUsingBlock:^(NSNumber *key, id obj, BOOL *stop) {
                        
                        NSFetchedResultsChangeType type = [key unsignedIntegerValue];
                        switch (type)
                        {
                            case NSFetchedResultsChangeInsert:
                                [self.collectionView insertSections:[NSIndexSet indexSetWithIndex:[obj unsignedIntegerValue]]];
                                break;
                            case NSFetchedResultsChangeDelete:
                                [self.collectionView deleteSections:[NSIndexSet indexSetWithIndex:[obj unsignedIntegerValue]]];
                                break;
                            case NSFetchedResultsChangeUpdate:
                                [self.collectionView reloadSections:[NSIndexSet indexSetWithIndex:[obj unsignedIntegerValue]]];
                                break;
                        }
                    }];
                }
            } completion:nil];
        }
        
        if ([_objectChanges count] > 0 && [_sectionChanges count] == 0)
        {
            [self.collectionView performBatchUpdates:^{
                
                for (NSDictionary *change in _objectChanges)
                {
                    [change enumerateKeysAndObjectsUsingBlock:^(NSNumber *key, id obj, BOOL *stop) {
                        
                        NSFetchedResultsChangeType type = [key unsignedIntegerValue];
                        switch (type)
                        {
                            case NSFetchedResultsChangeInsert:
                                [self.collectionView insertItemsAtIndexPaths:@[obj]];
                                break;
                            case NSFetchedResultsChangeDelete:
                                [self.collectionView deleteItemsAtIndexPaths:@[obj]];
                                break;
                            case NSFetchedResultsChangeUpdate:
                                [self.collectionView reloadItemsAtIndexPaths:@[obj]];
                                break;
                            case NSFetchedResultsChangeMove:
                                [self.collectionView moveItemAtIndexPath:obj[0] toIndexPath:obj[1]];
                                break;
                        }
                    }];
                }
            } completion:nil];
        }
    }
    
    [_sectionChanges removeAllObjects];
    [_objectChanges removeAllObjects];
}



@end
