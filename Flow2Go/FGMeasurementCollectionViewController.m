//
//  MeasurementCollectionViewController.m
//  Flow2Go
//
//  Created by Christian Hansen on 02/08/12.
//  Copyright (c) 2012 Christian Hansen. All rights reserved.
//

#import "FGMeasurementCollectionViewController.h"
#import "FGMeasurement+Management.h"
#import "FGDownloadManager.h"
#import "FGAnalysisViewController.h"
#import "FGFolder+Management.h"
#import "FGAnalysis+Management.h"
#import "KeywordTableViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "FGDropboxViewController.h"

@interface FGMeasurementCollectionViewController () <FGDownloadManagerProgressDelegate, UIActionSheetDelegate>

@property (nonatomic, strong) UIPopoverController *detailPopoverController;
@property (nonatomic, strong) NSMutableArray *editItems;

@end

@implementation FGMeasurementCollectionViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    UINib *cellNib = [UINib nibWithNibName:@"MeasurementView" bundle:NSBundle.mainBundle];
    [self.collectionshView registerNib:cellNib forCellWithReuseIdentifier:@"Measurement Cell"];
    [self _addGestures];
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.title = self.folder.name;
    FGDownloadManager.sharedInstance.progressDelegate = self;
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)_addGestures
{
    UILongPressGestureRecognizer *longPressRecognizer = [UILongPressGestureRecognizer.alloc initWithTarget:self action:@selector(handleLongPressGesture:)];
    [self.collectionView addGestureRecognizer:longPressRecognizer];
}


- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    if (!editing) [self _discardEditItems];
}


- (void)deleteTapped:(UIButton *)deleteButton
{
    NSString *deleteString = nil;
    if (self.editItems.count == 1) {
        deleteString = NSLocalizedString(@"Are you sure you want to delete selected item?", nil);
    } else {
        deleteString = NSLocalizedString(@"Are you sure you want to delete selected items?", nil);
    }
    UIActionSheet *actionSheet = [UIActionSheet.alloc initWithTitle:deleteString
                                                           delegate:self
                                                  cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                             destructiveButtonTitle:NSLocalizedString(@"Delete", nil)
                                                  otherButtonTitles: nil];
    [actionSheet showFromRect:deleteButton.frame inView:self.navigationController.navigationBar animated:YES];
}

- (void)navigationPaneBarButtonItemTapped:(UIBarButtonItem *)barButton
{
    [self.navigationPaneViewController setPaneState:MSNavigationPaneStateOpen animated:YES];
}


- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == actionSheet.cancelButtonIndex) return;
    NSArray *deleteItems = [self.editItems copy];
    [self.editItems removeAllObjects];
    [FGMeasurement deleteMeasurements:deleteItems];
}


- (void)addToTapped:(UIBarButtonItem *)addToButtom
{
    BOOL itemsSelected = NO;
    NSLog(@"add to tapped");
    if (self.editItems.count > 0) itemsSelected = YES;;
    
    switch (itemsSelected) {
        case YES:
            // show list of other folders to add files to
            break;
            
        case NO:
            // show list of other folders to add files from
            break;
            
        default:
            break;
    }
}

- (IBAction)infoButtonTapped:(UIButton *)infoButton
{
    UICollectionViewCell *cell = (UICollectionViewCell *)infoButton.superview.superview;
    NSIndexPath *indexPath = [self.collectionView indexPathForCell:cell];
    
    KeywordTableViewController *keywordTVC = [self.storyboard instantiateViewControllerWithIdentifier:@"measurementDetailViewController"];
    keywordTVC.measurement = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        if (self.detailPopoverController.isPopoverVisible) {
            [self.detailPopoverController dismissPopoverAnimated:YES];
        }
        self.detailPopoverController = [UIPopoverController.alloc initWithContentViewController:keywordTVC];
        [self.detailPopoverController presentPopoverFromRect:infoButton.frame inView:cell.contentView permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    } else if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
        [self presentViewController:keywordTVC animated:YES completion:nil];
    }
}


- (IBAction)folderTapped:(UIBarButtonItem *)doneButton
{
    [self.delegate measurementCollectionViewControllerDidTapDismiss:self];
//    [self.navigationPaneViewController dismissViewControllerAnimated:YES completion:nil];
}


- (void)configureCell:(UICollectionViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    FGMeasurement *measurement = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    UILabel *nameLabel = (UILabel *)[cell viewWithTag:1];
    nameLabel.text = measurement.filename;
    UIButton *infoButton = (UIButton *)[cell viewWithTag:4];

    if (measurement.downloadDate) {
        UILabel *dateLabel = (UILabel *)[cell viewWithTag:2];
        dateLabel.text = [NSDateFormatter localizedStringFromDate:measurement.downloadDate dateStyle:kCFDateFormatterMediumStyle timeStyle:kCFDateFormatterMediumStyle];
        
        UILabel *countLabel = (UILabel *)[cell viewWithTag:3];
        countLabel.text = measurement.countOfEvents.stringValue;
        
        infoButton.enabled = YES;
    } else {
        infoButton.enabled = NO;
    }
}


- (void)_toggleVisibleCheckmarkForCell:(UICollectionViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    Measurement *measurement = [self.fetchedResultsController objectAtIndexPath:indexPath];
    UIImageView *checkMarkImageView = (UIImageView *)[cell viewWithTag:5];
    checkMarkImageView.hidden = ![self.editItems containsObject:measurement];
}



- (void)_togglePresenceInEditItems:(FGMeasurement *)aMeasurement
{
    if (!self.editItems) self.editItems = NSMutableArray.array;
    if ([self.editItems containsObject:aMeasurement]) {
        [self.editItems removeObject:aMeasurement];
    } else {
        [self.editItems addObject:aMeasurement];
    }
}


- (void)_toggleBarButtonStateOnChangedEditItems
{
    BOOL hasItemsSelected = NO;
    if (self.editItems.count > 0) hasItemsSelected = YES;
    
    //[self.delegate measurementViewController:self hasItemsSelected:hasItemsSelected];
}


- (void)_discardEditItems
{
    NSMutableArray *editItems = [self.editItems copy];
    [self.editItems removeAllObjects];
    self.editItems = nil;
    for (Measurement *aMeasurement in editItems) {
        NSIndexPath *indexPath = [self.fetchedResultsController indexPathForObject:aMeasurement];
        UICollectionViewCell *cell = [self.collectionView cellForItemAtIndexPath:indexPath];
        [self _toggleVisibleCheckmarkForCell:cell atIndexPath:indexPath];
    }
}


- (void)_presentMeasurement:(FGMeasurement *)aMeasurement
{
    if (aMeasurement.analyses.lastObject == nil) {
        NSManagedObjectID *objectID = aMeasurement.objectID;
        __block NSManagedObjectID *analysisID;
        [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
            FGMeasurement *localMeasurement = (FGMeasurement *)[localContext objectWithID:objectID];
            analysisID = [FGAnalysis createAnalysisForMeasurement:localMeasurement].objectID;
        } completion:^(BOOL success, NSError *error) {
            FGAnalysis *analysis = (FGAnalysis *)[[NSManagedObjectContext defaultContext] objectWithID:analysisID];
            [self.analysisViewController showAnalysis:analysis];
        }];
    } else {
        [self.analysisViewController showAnalysis:aMeasurement.analyses.lastObject];
    }
}


#pragma mark - Download Manager progress delegate
- (void)downloadManager:(FGDownloadManager *)sender loadProgress:(CGFloat)progress forDestinationPath:(NSString *)destinationPath
{
    FGMeasurement *downloadingMeasurement = [FGMeasurement findFirstByAttribute:@"fGMeasurementID" withValue:destinationPath.lastPathComponent.stringByDeletingPathExtension];
    NSIndexPath *downloadIndex = [self.fetchedResultsController indexPathForObject:downloadingMeasurement];
    UICollectionViewCell *downloadCell = [self.collectionView cellForItemAtIndexPath:downloadIndex];
    UILabel *progressLabel = (UILabel *)[downloadCell viewWithTag:2];
    progressLabel.text = [NSString stringWithFormat:@"%.2f", progress];
}


#pragma mark - Collection View Data source
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    id <NSFetchedResultsSectionInfo> sectionInfo = self.fetchedResultsController.sections[section];
    return sectionInfo.numberOfObjects;
}


- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Measurement Cell"
                                                           forIndexPath:indexPath];
    [self configureCell:cell atIndexPath:indexPath];
    return cell;
}


- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    FGMeasurement *aMeasurement = (FGMeasurement *)[self.fetchedResultsController objectAtIndexPath:indexPath];
    if (!aMeasurement.isDownloaded) return;
    
    switch (self.isEditing) {
        case YES:
            [self _togglePresenceInEditItems:aMeasurement];
            [self _toggleVisibleCheckmarkForCell:[collectionView cellForItemAtIndexPath:indexPath] atIndexPath:indexPath];
            [self _toggleBarButtonStateOnChangedEditItems];
            break;
            
        case NO:
            [self _presentMeasurement:aMeasurement];
            break;
            
        default:
            break;
    }    
}


#pragma mark - Fetched results controller

- (NSFetchedResultsController *)fetchedResultsController
{
    if (_fetchedResultsController != nil) {
        return _fetchedResultsController;
    }
    
    NSFetchRequest *fetchRequest = [NSFetchRequest.alloc init];
    fetchRequest.entity = [NSEntityDescription entityForName:@"FGMeasurement"
                                      inManagedObjectContext:[NSManagedObjectContext MR_defaultContext]];
    
    // Set the batch size to a suitable number.
    fetchRequest.fetchBatchSize = 50;
    
    // Edit the sort key as appropriate.
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor.alloc initWithKey:@"filename" ascending:YES];
    
    NSArray *sortDescriptors = @[sortDescriptor];
    fetchRequest.sortDescriptors = sortDescriptors;
    if (self.folder.measurements) fetchRequest.predicate = [NSPredicate predicateWithFormat:@"SELF IN %@", self.folder.measurements];

    
    // Edit the section name key path and cache name if appropriate.
    // nil for section name key path means "no sections".
    NSFetchedResultsController *aFetchedResultsController = [NSFetchedResultsController.alloc initWithFetchRequest:fetchRequest
                                                                                              managedObjectContext:[NSManagedObjectContext MR_defaultContext].parentContext
                                                                                                sectionNameKeyPath:nil
                                                                                                         cacheName:nil];
    aFetchedResultsController.delegate = self;
    self.fetchedResultsController = aFetchedResultsController;
    
	NSError *error = nil;
	if (![self.fetchedResultsController performFetch:&error]) {
        // Replace this implementation with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
	    NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
	    abort();
	}
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


@end
