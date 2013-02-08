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
#import "FGFolder.h"
#import "FGAnalysis+Management.h"
#import "KeywordTableViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "KGNoise.h"
#import "UIBarButtonItem+Customview.h"

@interface FGMeasurementCollectionViewController () <FGDownloadManagerProgressDelegate, UIActionSheetDelegate>

@property (nonatomic, strong) UIPopoverController *detailPopoverController;
@property (nonatomic, strong) NSMutableArray *editItems;
@property (nonatomic, strong) NSMutableArray *objectChanges;
@property (nonatomic, strong) NSMutableArray *sectionChanges;

@end

@implementation FGMeasurementCollectionViewController

- (void)awakeFromNib
{
    [super awakeFromNib];
    _objectChanges = [NSMutableArray array];
    _sectionChanges = [NSMutableArray array];
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    UINib *cellNib = [UINib nibWithNibName:@"MeasurementView" bundle:NSBundle.mainBundle];
    [self.collectionView registerNib:cellNib forCellWithReuseIdentifier:@"Measurement Cell"];
    [self _addGestures];
    [self _addNoiseBackground];
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.title = self.folder.name;
    FGDownloadManager.sharedInstance.progressDelegate = self;
    [self _configureBarButtonItem];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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


- (void)_configureBarButtonItem
{
    UIBarButtonItem *folderButton = [UIBarButtonItem barButtonWithImage:[UIImage imageNamed:@"53-house"] style:UIBarButtonItemStylePlain target:self action:@selector(folderTapped:)];
    [self.navigationItem setLeftBarButtonItems:@[folderButton] animated:YES];
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
    
    FGAnalysis *analysis = aMeasurement.analyses.lastObject;
    if (analysis == nil) {
        analysis = [FGAnalysis createAnalysisForMeasurement:aMeasurement];
        NSError *error;
        if(![analysis.managedObjectContext obtainPermanentIDsForObjects:@[analysis] error:&error]) NSLog(@"Error obtaining perm ID: %@", error.localizedDescription);
    }
    [self.analysisViewController showAnalysis:analysis];
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
    NSLog(@"didSelectItemAtIndexPath: %@", self);
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
    _fetchedResultsController = [FGMeasurement fetchAllGroupedBy:nil
                                                   withPredicate:[NSPredicate predicateWithFormat:@"SELF IN %@", self.folder.measurements]
                                                        sortedBy:@"filename"
                                                       ascending:YES
                                                        delegate:self
                                                       inContext:[NSManagedObjectContext MR_defaultContext]];
    return _fetchedResultsController;
}








































#pragma mark - Fetched Results Controller Delegate methods
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
