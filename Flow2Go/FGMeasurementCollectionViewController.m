//
//  FolderCollectionViewController.m
//  Flow2Go
//
//  Created by Christian Hansen on 19/09/12.
//  Copyright (c) 2012 Christian Hansen. All rights reserved.
//

#import "FGMeasurementCollectionViewController.h"
#import "FGDownloadManager.h"
#import "UIBarButtonItem+Customview.h"
#import "FGMeasurementHeaderView.h"
#import "FGMeasurementCell.h"
#import "FGMeasurementGridLayout.h"
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
#import "FGKeywordTableViewController.h"
#import "FGAnalysisManager.h"
#import "FGSampleImporter.h"
#import "MKStoreManager.h"

@interface FGMeasurementCollectionViewController () <UIActionSheetDelegate, FGDownloadManagerProgressDelegate, UIPopoverControllerDelegate, UIAlertViewDelegate>

@property (nonatomic, strong) NSMutableArray *editItems;
@property (nonatomic, strong) UIBarButtonItem *leftBarButtonItem;
@property (nonatomic, strong) NSMutableArray *objectChanges;
@property (nonatomic, strong) NSMutableArray *sectionChanges;
@property (nonatomic) CGFloat verticalContentOffsetFraction;
@property (nonatomic, strong) UIPopoverController *infoPopoverController;
@property (nonatomic, strong) UIPopoverController *filePickerPopoverController;


@end

@implementation FGMeasurementCollectionViewController

- (void)awakeFromNib
{
    [super awakeFromNib];
    self.sectionChanges = [NSMutableArray array];
    self.objectChanges = [NSMutableArray array];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"Flow2Go";
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
    [FGSampleImporter importSamplesIfFirstLaunch];
    [[FGDownloadManager sharedInstance] refreshDownloadStates];
    [[FGAnalysisManager sharedInstance] createRootPlotsForMeasurementsWithoutPlotsWithCompletion:nil];
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
        UIBarButtonItem *deleteItem = [UIBarButtonItem barButtonWithImage:[UIImage imageNamed:@"0210"] style:UIBarButtonItemStylePlain target:self action:@selector(deleteTapped:)];
        deleteItem.enabled = NO;
        [self.navigationItem setLeftBarButtonItems:@[deleteItem] animated:YES]; //uploadButton removed 
        [self.navigationItem setRightBarButtonItems:@[self.editButtonItem] animated:YES];
    } else {
        UIBarButtonItem *importButton = [UIBarButtonItem barButtonWithImage:[UIImage imageNamed:@"0107"] style:UIBarButtonItemStylePlain target:self action:@selector(importFromCloudTapped:)];
        [self.navigationItem setLeftBarButtonItems:@[importButton] animated:YES];
        [self.navigationItem setRightBarButtonItems:@[self.editButtonItem] animated:YES];
    }
}

#pragma mark Import/Export
- (void)importFromCloudTapped:(UIButton *)sender
{
    [self performSegueWithIdentifier:@"Show Dropbox" sender:self];
}


- (void)exportToCloudTapped:(id)sender
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
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
    self.navigationController.view.superview.frame = newFrame;
}

- (void)_updatePaneViewControllerOpenWidthForInterfaceOrientation:(UIInterfaceOrientation)orientation
{
//    if (self.interfaceOrientation == orientation) {
//        self.navigationPaneViewController.openStateRevealWidth = self.view.bounds.size.width - PANE_COVER_WIDTH;
//    } else {
//        CGFloat revealWidth = self.view.bounds.size.height - PANE_COVER_WIDTH;
//        if (![[UIApplication sharedApplication] isStatusBarHidden]) revealWidth += 20.0f;
//        if (!self.navigationController.navigationBar.isHidden) revealWidth += self.navigationController.navigationBar.frame.size.height;
//        self.navigationPaneViewController.openStateRevealWidth = revealWidth;
//    }
    self.navigationPaneViewController.openStateRevealWidth = PANE_REVEAL_WIDTH;
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
    //[self.navigationItem.leftBarButtonItems[1] setEnabled:(self.editItems.count > 0)]; removed upload button for now
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
        UICollectionViewCell *cell = [self.collectionView cellForItemAtIndexPath:indexPath];
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

- (void)filePickerCancelled
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark Apptentive
#pragma mark - Apptentive
- (void)_observings
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(surveyBecameAvailable:) name:ATSurveyNewSurveyAvailableNotification object:nil];
    [ATSurveys checkForAvailableSurveys];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(headerControlsWillAppear:) name:FGHeaderControlsWillAppearNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDidSaveNotification:) name:NSManagedObjectContextDidSaveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(filePickerCancelled) name:FGPickerViewControllerCancelledNotification object:nil];
}

- (void)surveyBecameAvailable:(NSNotification *)notification
{
    [ATSurveys presentSurveyControllerFromViewController:self];
}



#pragma mark UISearchBar delegate
- (void)headerControlsWillAppear:(NSNotification *)notification
{
//    UISearchBar *searchBar = notification.userInfo[@"searchBar"];
//    searchBar.delegate = self;
    UISegmentedControl *segmentedControl = notification.userInfo[@"segmentedControl"];
    segmentedControl.selectedSegmentIndex = [self.collectionView.collectionViewLayout isKindOfClass:[FGStackedLayout class]] ? 0 : 1;
}


- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    NSLog(@"search text: %@", searchText);
}


#define FILENAME_CHARACTER_COUNT 29

- (void)configureCell:(UICollectionViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{    
    FGMeasurement *measurement = [self.fetchedResultsController objectAtIndexPath:indexPath];
    FGMeasurementCell *measurementCell = (FGMeasurementCell *)cell;
    FGDownloadState downloadState = [measurement state];
    [measurementCell setState:downloadState isEditing:self.isEditing];
    measurementCell.fileNameLabel.text = [measurement.filename fitToLength:FILENAME_CHARACTER_COUNT];
    if (!self.isEditing) measurementCell.checkMarkImageView.hidden = YES;
    measurementCell.checkMarkImageView.hidden = ![self.editItems containsObject:measurement];
    measurementCell.infoButton.hidden = self.isEditing;

    switch (downloadState) {
        case FGDownloadStateDownloaded:
            measurementCell.dateLabel.text = [measurement.downloadDate readableDate];
            measurementCell.thumbImageView.image = measurement.thumbImage;
            measurementCell.eventCountLabel.text = measurement.countOfEvents.stringValue;
            [measurementCell.infoButton addTarget:self action:@selector(infoButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
            break;
            
        default:
            
            break;
    }
}

#pragma - Info Popover
- (void)infoButtonTapped:(UIButton *)infoButton
{
    CGPoint popoverLocation = [infoButton.superview convertPoint:infoButton.center toView:self.view];
    CGPoint buttonLocationInCollectionView = [infoButton.superview convertPoint:infoButton.center toView:self.collectionView];
    NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:buttonLocationInCollectionView];
    FGMeasurement *measurement = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    FGKeywordTableViewController *keywordViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"keywordTableViewController"];
    keywordViewController.measurement = measurement;    
    if (self.infoPopoverController.isPopoverVisible) [self.infoPopoverController dismissPopoverAnimated:YES];
    if (IS_IPAD) {
        self.infoPopoverController = [UIPopoverController.alloc initWithContentViewController:keywordViewController];
        self.infoPopoverController.delegate = self;
        [self.infoPopoverController presentPopoverFromRect:CGRectMake(popoverLocation.x - 0.5f, popoverLocation.y - 0.5f, 1, 1) inView:self.view permittedArrowDirections:(UIPopoverArrowDirectionDown | UIPopoverArrowDirectionUp) animated:YES];
    } else {
//        [self presentViewController:plotNavigationVC animated:YES completion:nil];
    }
}


- (void)reloadButtonTapped:(UIButton *)reloadButton
{
    CGPoint buttonLocationInCollectionView = [reloadButton.superview convertPoint:reloadButton.center toView:self.collectionView];
    NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:buttonLocationInCollectionView];
    FGMeasurement *measurement = [self.fetchedResultsController objectAtIndexPath:indexPath];
    if ([measurement state] == FGDownloadStateFailed) {
        [[FGDownloadManager sharedInstance] retryFailedDownload:measurement];
    }
}

- (void)_createRootPlotsFor:(FGMeasurement *)measurement
{
    if (!measurement) return;
    [[FGAnalysisManager sharedInstance] createRootPlotsForMeasurements:@[measurement]];
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
    FGMeasurementCell *downloadCell = (FGMeasurementCell *)[self.collectionView cellForItemAtIndexPath:[self.fetchedResultsController indexPathForObject:measurement]];
    NSIndexPath *indexPath = [self.fetchedResultsController indexPathForObject:measurement];
    [self configureCell:downloadCell atIndexPath:indexPath];
    [self _createRootPlotsFor:measurement];
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
    static NSString *MeasurementCellIdentifier = @"Measurement Cell";
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:MeasurementCellIdentifier forIndexPath:indexPath];
    [self configureCell:cell atIndexPath:indexPath];
    return cell;
}


- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        static NSString *MeasurementHeaderIdentifier = @"Measurement Header View";
        FGMeasurementHeaderView *headerView = (FGMeasurementHeaderView *)[collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:MeasurementHeaderIdentifier forIndexPath:indexPath];
        id <NSFetchedResultsSectionInfo> section = self.fetchedResultsController.sections[indexPath.section];
        headerView.titleLabel.text = [section name];
        return headerView;
    }
    return nil;
}

#pragma mark - UICollectionView delegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    FGMeasurement *measurement = [self.fetchedResultsController objectAtIndexPath:indexPath];
    if ([measurement state] == FGDownloadStateFailed) {
        [[FGDownloadManager sharedInstance] retryFailedDownload:measurement];
        return;
    }
    UICollectionViewCell *cell = [self.collectionView cellForItemAtIndexPath:indexPath];
    switch (self.isEditing) {
        case NO:
            if ([self isFCSViewingPurchased] || [self isSampleMeasurement:measurement]) {
                [self _presentMeasurement:measurement];
            } else {
                [self showPleaseUpgradeAlert];
            }
            break;

        case YES:
            [self _togglePresenceInEditItems:measurement];
            [self _updateCheckmarkVisibilityForCell:cell atIndexPath:indexPath];
            [self _toggleBarButtonStateOnChangedEditItems];
            break;
    }
}



- (void)_presentMeasurement:(FGMeasurement *)aMeasurement
{
    if ([aMeasurement state] != FGDownloadStateDownloaded) return;
    
    FGAnalysis *analysis = aMeasurement.analyses.lastObject;
    if (analysis == nil) {
        analysis = [FGAnalysis createAnalysisForMeasurement:aMeasurement];
        NSError *error;
        if(![analysis.managedObjectContext obtainPermanentIDsForObjects:@[analysis] error:&error]) NSLog(@"Error obtaining perm ID: %@", error.localizedDescription);
    }
    [self.analysisViewController showAnalysis:analysis];
//    [self changeBounds];
}


- (void)changeBounds
{
    self.verticalContentOffsetFraction = self.collectionView.contentOffset.y / self.collectionView.contentSize.height;
    FGMeasurementGridLayout *newGridLayout = [[FGMeasurementGridLayout alloc] init];
    newGridLayout.sectionInset = UIEdgeInsetsMake(5, 25, 40, 500);
    [self.collectionView setCollectionViewLayout:newGridLayout animated:YES];
    if (self.verticalContentOffsetFraction > 0.0f && self.verticalContentOffsetFraction < 1.0f) {
        CGFloat verticalContentOffset = self.collectionView.contentSize.height * self.verticalContentOffsetFraction;
        self.collectionView.contentOffset = CGPointMake(0, verticalContentOffset);
    } else {
        self.collectionView.contentOffset = CGPointMake(0, [FGHeaderControlsView defaultSize].height);
    }
//    [UIView animateWithDuration:5.0 delay:0.0 options:UIViewAnimationOptionAllowAnimatedContent animations:^{
//        [(UICollectionViewFlowLayout *)self.collectionView.collectionViewLayout setSectionInset:UIEdgeInsetsMake(5, 25, 40, 500)];
//    } completion:nil];
}


#pragma mark - In App Purchase Check
- (BOOL)isFCSViewingPurchased
{
    return ([MKStoreManager isFeaturePurchased:InAppIdentifierFCSFiles]);
}


- (BOOL)isSampleMeasurement:(FGMeasurement *)measurement
{
    if ([measurement.fGMeasurementID isEqualToString:SampleFileCheckSum1]
        || [measurement.fGMeasurementID isEqualToString:SampleFileCheckSum2]) {
        return YES;
    }
    return NO;
}

- (void)showPleaseUpgradeAlert
{
    NSString *message = NSLocalizedString(@"Thank you for using Flow2Go! Please upgrade to view your own FCS files.", nil);

    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Please Upgrade", nil)
                                                        message:message
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                              otherButtonTitles:NSLocalizedString(@"Upgrade...", nil), nil];
    [alertView show];
}



#pragma mark - Alert View Delegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == alertView.cancelButtonIndex) {
        return;
    }
    [self performSegueWithIdentifier:@"Show Store" sender:nil];
}


#pragma mark - Fetched results controller
- (NSFetchedResultsController *)fetchedResultsController
{
    if (_fetchedResultsController != nil) {
        return _fetchedResultsController;
    }
    _fetchedResultsController = [FGMeasurement fetchAllSortedBy:@"folder.createdAt"
                                                      ascending:NO
                                                  withPredicate:nil
                                                        groupBy:@"folder.name"
                                                       delegate:self
                                                      inContext:[NSManagedObjectContext defaultContext]];
    
    
    return _fetchedResultsController;
}




















































#pragma mark - NSManagedContext
- (void)handleDidSaveNotification:(NSNotification *)notification
{
    //NSLog(@"%s", __PRETTY_FUNCTION__);
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
    @try {
        [self _performOutstandingCollectionViewUpdates];
    }
    @catch (NSException *exception) {
        NSLog(@"Exception (_performOutstandingCollectionViewUpdates): %@", exception.reason);
        [self.sectionChanges removeAllObjects];
        [self.objectChanges removeAllObjects];
        [self.collectionView reloadData];
    }
    @finally {
        // Nothing
    }
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
                                [self configureCell:[self.collectionView cellForItemAtIndexPath:obj] atIndexPath:obj];
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
    [self.sectionChanges removeAllObjects];
    [self.objectChanges removeAllObjects];
}



@end
