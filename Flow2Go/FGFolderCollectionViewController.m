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
#import "FGMeasurementCollectionViewController.h"
#import "UIBarButtonItem+Customview.h"
#import "FGFolderCell.h"
#import "KGNoise.h"
#import "FGFolderLayout.h"
#import "FGMeasurement+Management.h"
#import "NSString+_Format.h"
#import "NSDate+Formatting.h"

@interface FGFolderCollectionViewController () <UIAlertViewDelegate, MeasurementCollectionViewControllerDelegate, UIActionSheetDelegate, FGDownloadManagerProgressDelegate>
@property (nonatomic, strong) NSMutableArray *editItems;
@property (nonatomic, strong) UIBarButtonItem *leftBarButtonItem;
@property (nonatomic, strong) NSMutableArray *objectChanges;
@property (nonatomic, strong) NSMutableArray *sectionChanges;

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
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self _updateVisibleCells];
    [FGDownloadManager.sharedInstance setProgressDelegate:self];
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


- (void)measurementCollectionViewControllerDidTapDismiss:(id)sender
{
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}


- (void)_addNoiseBackground
{
    KGNoiseRadialGradientView *collectionNoiseView = [[KGNoiseRadialGradientView alloc] initWithFrame:self.collectionView.bounds];
    collectionNoiseView.backgroundColor            = [UIColor colorWithWhite:0.7032 alpha:1.000];
    collectionNoiseView.alternateBackgroundColor   = [UIColor colorWithWhite:0.7051 alpha:1.000];
    collectionNoiseView.noiseOpacity = 0.07;
    collectionNoiseView.noiseBlendMode = kCGBlendModeNormal;
    self.collectionView.backgroundView = collectionNoiseView;
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


- (void)deleteTapped:(UIButton *)deleteButton
{
    NSString *deleteString = nil;
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
        [FGFolder deleteFolders:deleteItems completion:^(NSError *error) {
            if (error) NSLog(@"Error: %@", error.localizedDescription);
        }];
    }
    [self setEditing:NO animated:YES];
}


- (void)_updateCheckmarkVisibilityForCell:(UICollectionViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    id anObject = [self.fetchedResultsController objectAtIndexPath:indexPath];
    [(FGFolderCell *)cell checkMarkImageView].hidden = ![self.editItems containsObject:anObject];
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


#define FOLDER_NAME_MAX_CHARACTER_COUNT 29
- (void)configureCell:(UICollectionViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    FGFolder *folder = [self.fetchedResultsController objectAtIndexPath:indexPath];
    FGFolderCell *folderCell = (FGFolderCell *)cell;
    folderCell.nameLabel.text = [folder.name fitToLength:FOLDER_NAME_MAX_CHARACTER_COUNT];
    folderCell.checkMarkImageView.hidden = (![self.editItems containsObject:folder]);
    folderCell.countLabel.text = (folder.measurements.count > 0) ? [NSString stringWithFormat:@"%d", folder.measurements.count] : @"0";
    if (![folder hasActiveDownloads]) [folderCell.spinner stopAnimating];
    folderCell.downloadCountLabel.hidden = ![folder hasActiveDownloads];
    folderCell.dateLabel.text = [[folder downloadDateOfNewestMeasurement] readableDate];
}


- (void)newFolderTapped:(UIBarButtonItem *)addButton
{
    UIAlertView *alertView = [UIAlertView.alloc initWithTitle:NSLocalizedString(@"Add Name", nil) message:nil delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) otherButtonTitles:NSLocalizedString(@"Add", nil), nil];
    alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
    [alertView show];
}

#pragma mark - UIAlertView delegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) {
        NSString *folderName = [alertView textFieldAtIndex:0].text;
        [FGFolder createWithName:folderName];
    }
}

#pragma mark - Download Manager progress delegate
- (void)downloadManager:(FGDownloadManager *)downloadManager beganDownloadingMeasurement:(FGMeasurement *)measurement
{
    [self _updateDownloadProgressView:downloadManager forMeasurement:measurement];
}

- (void)downloadManager:(FGDownloadManager *)downloadManager loadProgress:(CGFloat)progress forMeasurement:(FGMeasurement *)measurement
{
    [self _updateDownloadProgressView:downloadManager forMeasurement:measurement];
}

- (void)downloadManager:(FGDownloadManager *)downloadManager finishedDownloadingMeasurement:(FGMeasurement *)measurement
{
    [self _updateDownloadProgressView:downloadManager forMeasurement:measurement];
}

- (void)downloadManager:(FGDownloadManager *)downloadManager failedDownloadingMeasurement:(FGMeasurement *)measurement
{
    //TODO: figure out how to configure cell when a download failed
//    [self _updateDownloadProgressView:downloadManager forMeasurement:measurement];
    NSLog(@"failedDownloadingMeasurement: %@", measurement);
}


- (void)_updateDownloadProgressView:(FGDownloadManager *)manager forMeasurement:(FGMeasurement *)measurement
{
    FGFolder *folder = measurement.folder;
    FGFolderCell *downloadCell = (FGFolderCell *)[self.collectionView cellForItemAtIndexPath:[self.fetchedResultsController indexPathForObject:folder]];
    NSArray *downloadsForFolder = [folder.measurements.array filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"isDownloaded == NO"]];
    downloadCell.spinner.hidden = (downloadsForFolder.count == 0) ? YES : NO;
    if (!downloadCell.spinner.isHidden && !downloadCell.spinner.isAnimating) [downloadCell.spinner startAnimating];
    downloadCell.downloadCountLabel.hidden = (downloadsForFolder.count == 0) ? YES : NO;
    downloadCell.downloadCountLabel.text = [NSString stringWithFormat:@"%d", downloadsForFolder.count];
}

#pragma mark - Collection View Data source
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    id <NSFetchedResultsSectionInfo> sectionInfo = self.fetchedResultsController.sections[section];
    return sectionInfo.numberOfObjects;
}


- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Folder Cell" forIndexPath:indexPath];
    [self configureCell:cell atIndexPath:indexPath];
    return cell;
}

#pragma mark - UICollectionView delegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    FGFolder *selectedFolder = [self.fetchedResultsController objectAtIndexPath:indexPath];
    UICollectionViewCell *cell = [self.collectionView cellForItemAtIndexPath:indexPath];
    switch (self.isEditing) {
        case YES:
            [self _togglePresenceInEditItems:selectedFolder];
            [self _updateCheckmarkVisibilityForCell:cell atIndexPath:indexPath];
            [self _toggleBarButtonStateOnChangedEditItems];
            break;
            
        case NO:
            [self _showFolder:selectedFolder];
            break;
    }
}


- (void)_showFolder:(FGFolder *)folder
{
    MSNavigationPaneViewController *navigationPaneViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"paneNavigationController"];
    UINavigationController *measurementNavigationController = [self.storyboard instantiateViewControllerWithIdentifier:@"measurement VC NavigationCon"];
    FGMeasurementCollectionViewController *measurementViewController = (FGMeasurementCollectionViewController *)[measurementNavigationController topViewController];
    measurementViewController.delegate = self;
    measurementViewController.folder = folder;
    measurementViewController.navigationPaneViewController = navigationPaneViewController;
    navigationPaneViewController.masterViewController = measurementNavigationController;
    [navigationPaneViewController setPaneState:MSNavigationPaneStateClosed animated:NO];
    
    UINavigationController *analysisNavigationController = [self.storyboard instantiateViewControllerWithIdentifier:@"analysisViewControllerNavigationController"];
    [navigationPaneViewController setPaneViewController:analysisNavigationController animated:NO completion:nil];
    measurementViewController.analysisViewController = (FGAnalysisViewController *)analysisNavigationController.topViewController;

    UIBarButtonItem *navigationPaneBarButton = [UIBarButtonItem barButtonWithImage:[UIImage imageNamed:@"FGBarButtonIconNavigationPane"] style:UIBarButtonItemStylePlain target:measurementViewController action:@selector(togglePaneTapped:)];
    [(UIViewController *)measurementViewController.analysisViewController navigationItem].leftBarButtonItem = navigationPaneBarButton;
    
    navigationPaneViewController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    [self presentViewController:navigationPaneViewController animated:YES completion:^{
        [navigationPaneViewController setPaneState:MSNavigationPaneStateOpen animated:YES];
    }];
}

#pragma mark - Fetched results controller

- (NSFetchedResultsController *)fetchedResultsController
{
    if (_fetchedResultsController != nil) {
        return _fetchedResultsController;
    }
    _fetchedResultsController = [FGFolder fetchAllGroupedBy:nil
                                              withPredicate:nil
                                                   sortedBy:@"name"
                                                  ascending:YES
                                                   delegate:self
                                                  inContext:[NSManagedObjectContext MR_defaultContext]];
    return _fetchedResultsController;
}

#pragma mark Fetched Results Controller Delegate methods
- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
    NSMutableDictionary *change = [NSMutableDictionary new];
    switch(type)
    {
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
    switch(type)
    {
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
