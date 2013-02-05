//
//  FolderCollectionViewController.m
//  Flow2Go
//
//  Created by Christian Hansen on 19/09/12.
//  Copyright (c) 2012 Christian Hansen. All rights reserved.
//

#import "FolderCollectionViewController.h"
#import "FGFolder+Management.h"
#import "DownloadManager.h"
#import "PinchLayout.h"
#import "MeasurementCollectionViewController.h"
#import "UIBarButtonItem+Customview.h"
#import "F2GFolderCell.h"
#import "DummyViewController.h"

@interface FolderCollectionViewController () <UIAlertViewDelegate, MeasurementCollectionViewControllerDelegate, UIActionSheetDelegate>
@property (nonatomic, strong) NSMutableArray *editItems;
@property (nonatomic, strong) UIBarButtonItem *leftBarButtonItem;
@end

@implementation FolderCollectionViewController 

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self _addGestures];
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
    if (!editing) [self _discardEditItems];
    [self _updateVisibleCells];
}

- (void)_addGestures
{
    UIPinchGestureRecognizer *pinchRecognizer = [UIPinchGestureRecognizer.alloc initWithTarget:self action:@selector(handlePinchGesture:)];
    [self.collectionView addGestureRecognizer:pinchRecognizer];
}


- (void)measurementCollectionViewControllerDidTapDismiss:(id)sender
{
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - Editing state
- (void)_configureBarButtonItemsForEditing:(BOOL)editing
{
    if (editing) {
        UIBarButtonItem *uploadButton = [UIBarButtonItem barButtonWithImage:[UIImage imageNamed:@"0108"] style:UIBarButtonItemStylePlain target:self action:@selector(exportToCloudTapped:)];
        UIBarButtonItem *deleteItem = [UIBarButtonItem deleteButtonWithTarget:self action:@selector(deleteTapped:)];
        uploadButton.enabled = NO;
        deleteItem.enabled = NO;
        [self.navigationItem setLeftBarButtonItems:@[uploadButton, deleteItem] animated:YES];
        [self.navigationItem setRightBarButtonItems:@[self.editButtonItem] animated:YES];
    } else {
        UIBarButtonItem *uploadButton = [UIBarButtonItem barButtonWithImage:[UIImage imageNamed:@"0107"] style:UIBarButtonItemStylePlain target:self action:@selector(importFromCloudTapped:)];
        UIBarButtonItem *addFolderButton = [UIBarButtonItem.alloc initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(newFolderTapped:)];
        [self.navigationItem setLeftBarButtonItems:@[uploadButton, addFolderButton] animated:YES];
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
    [(F2GFolderCell *)cell checkMarkImageView].hidden = ![self.editItems containsObject:anObject];
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
        F2GFolderCell *cell = (F2GFolderCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
        [self configureCell:cell atIndexPath:indexPath];
    }
}


- (void)configureCell:(UICollectionViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    FGFolder *folder = [self.fetchedResultsController objectAtIndexPath:indexPath];
    F2GFolderCell *folderCell = (F2GFolderCell *)cell;
    folderCell.nameLabel.text = folder.name;
    UILabel *countLabel = (UILabel *)[cell viewWithTag:2];
    countLabel.text = [NSString stringWithFormat:@"%i", folder.measurements.count];
}


- (void)newFolderTapped:(UIBarButtonItem *)addButton
{
    UIAlertView *alertView = [UIAlertView.alloc initWithTitle:NSLocalizedString(@"Add Name", nil) message:nil delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) otherButtonTitles:NSLocalizedString(@"Add", nil), nil];
    alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
    [alertView show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) {
        NSString *folderName = [alertView textFieldAtIndex:0].text;
        [FGFolder createWithName:folderName];
    }
}

#pragma mark - Download Manager progress delegate
- (void)downloadManager:(DownloadManager *)sender loadProgress:(CGFloat)progress forDestinationPath:(NSString *)destinationPath
{
//    Folder *downloadingFolder = [Folder findFirstByAttribute:@"name" withValue:];
//    NSIndexPath *downloadIndex = [self.fetchedResultsController indexPathForObject:downloadingMeasurement];
//    UICollectionViewCell *downloadCell = [self.collectionView cellForItemAtIndexPath:downloadIndex];
//    UILabel *progressLabel = (UILabel *)[downloadCell viewWithTag:2];
//    progressLabel.text = [NSString stringWithFormat:@"%.2f", progress];
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


- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    Folder *selectedFolder = [self.fetchedResultsController objectAtIndexPath:indexPath];
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


- (void)_showFolder:(Folder *)folder
{
    MSNavigationPaneViewController *navigationPaneViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"paneNavigationController"];
    UINavigationController *navigationController = [self.storyboard instantiateViewControllerWithIdentifier:@"measurement VC NavigationCon"];
    MeasurementCollectionViewController *measurementViewController = (MeasurementCollectionViewController *)[navigationController topViewController];
    measurementViewController.delegate = self;
    measurementViewController.folder = folder;
    measurementViewController.navigationPaneViewController = navigationPaneViewController;
    navigationPaneViewController.masterViewController = navigationController;
    [navigationPaneViewController setPaneState:MSNavigationPaneStateClosed animated:NO];
    
    UIViewController *viewController = [self.storyboard instantiateViewControllerWithIdentifier:@"analysisViewControllerNavigationController"];
    [navigationPaneViewController setPaneViewController:viewController animated:NO completion:nil];
    
    [self presentViewController:navigationPaneViewController animated:YES completion:^{
        [navigationPaneViewController setPaneState:MSNavigationPaneStateOpen animated:YES];
    }];
}

#pragma mark - Save changes from other contexts
- (void)handleDidSaveNotification:(NSNotification *)notification
{
    [[NSManagedObjectContext MR_defaultContext] mergeChangesFromContextDidSaveNotification:notification];
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
                                                  ascending:NO
                                                   delegate:self
                                                  inContext:[NSManagedObjectContext MR_defaultContext]];
    return _fetchedResultsController;
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
    UICollectionView *collectionView = self.collectionView;
        
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [self.collectionView insertItemsAtIndexPaths:@[newIndexPath]];
            break;
            
        case NSFetchedResultsChangeDelete:
            [collectionView deleteItemsAtIndexPaths:@[indexPath]];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [self configureCell:[collectionView cellForItemAtIndexPath:indexPath] atIndexPath:indexPath];
            break;
            
        case NSFetchedResultsChangeMove:
            [collectionView deleteItemsAtIndexPaths:@[indexPath]];
            [collectionView insertItemsAtIndexPaths:@[newIndexPath]];
            break;
    }
}


#pragma mark - Pinch effect
- (void)handlePinchGesture:(UIPinchGestureRecognizer *)sender
{
    PinchLayout* pinchLayout = (PinchLayout*)self.collectionView.collectionViewLayout;
    switch (sender.state) {
        case UIGestureRecognizerStateBegan:
        {
            CGPoint initialPinchPoint = [sender locationInView:self.collectionView];
            NSIndexPath* pinchedCellPath = [self.collectionView indexPathForItemAtPoint:initialPinchPoint];
            pinchLayout.pinchedCellPath = pinchedCellPath;
        }
            break;
            
        case UIGestureRecognizerStateChanged:
        {
            pinchLayout.pinchedCellScale = sender.scale;
            pinchLayout.pinchedCellCenter = [sender locationInView:self.collectionView];
        }
            
        default:
        {
            [self.collectionView performBatchUpdates:^{
                pinchLayout.pinchedCellPath = nil;
                pinchLayout.pinchedCellScale = 1.0;
            } completion:nil];
        }
            break;
    }
}


@end
