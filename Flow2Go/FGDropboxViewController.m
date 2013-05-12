//
//  DropboxViewController.m
//  Flow2Go
//
//  Created by Christian Hansen on 02/08/12.
//  Copyright (c) 2012 Christian Hansen. All rights reserved.
//

#import "FGDropboxViewController.h"
#import "FGDownloadManager.h"
#import "FGDropboxCell.h"
#import "NSString+_Format.h"
#import "UIBarButtonItem+Customview.h"
#import "UIImage+Alpha.h"
#import "FGMeasurement+Management.h"
#import "FGFolderPickerTableViewController.h"

@interface FGDropboxViewController () <FGDownloadManagerDelegate, FGFolderPickerDelegate>

@property (nonatomic, strong) NSArray *directoryContents;
@property (nonatomic, strong) NSMutableArray *selectedItems;
@property (nonatomic, strong) UIBarButtonItem *tempBarButtonItem;

@end

@implementation FGDropboxViewController

- (void)viewDidLoad
{
    [super viewDidLoad]; 
    [self _addObservers];
    [self _addPullToRefresh];
    [self _setSelectSubitemsState];
    if (!self.subPath) {
        self.subPath = @"";
        self.title = @"Dropbox";
    }
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (!DBSession.sharedSession.isLinked) {
        [DBSession.sharedSession linkFromController:self];
    } else {
        [self _requestFolderList];
    }
}

- (void)dealloc
{
    [NSNotificationCenter.defaultCenter removeObserver:self];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"Show Folder Picker"]) {
        FGFolderPickerTableViewController *folderPickerTableViewController = (FGFolderPickerTableViewController *)[(UINavigationController *)segue.destinationViewController topViewController];
        folderPickerTableViewController.delegate = self;
    }
}

- (NSMutableArray *)selectedItems
{
    if (!_selectedItems) {
        _selectedItems = [NSMutableArray new];
    }
    return _selectedItems;
}

- (void)setDirectoryContents:(NSArray *)directoryContents
{
    if (_directoryContents != directoryContents) {
        _directoryContents = directoryContents;
        [self.tableView reloadData];
    }
}

- (IBAction)doneTapped:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}


- (void)_cancelTapped
{
    [self.selectedItems removeAllObjects];
    [self _setSelectSubitemsState];
    [self.tableView reloadData];
}


- (void)_addObservers
{
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(_requestFolderList)
                                               name:DropboxLinkedNotification
                                             object:nil];
}

- (void)_addPullToRefresh
{
    UIRefreshControl *refreshControl = [UIRefreshControl new];
    [refreshControl addTarget:self action:@selector(_requestFolderList) forControlEvents:UIControlEventValueChanged];
    refreshControl.tintColor = [UIColor lightGrayColor];
    self.refreshControl = refreshControl;
}

- (void)_requestFolderList
{
    if (DBSession.sharedSession.isLinked) {
        FGDownloadManager.sharedInstance.delegate = self;
        [self _showSpinner:YES];
        [FGDownloadManager.sharedInstance.restClient loadMetadata:[DropboxBaseURL stringByAppendingPathComponent:self.subPath]];
    } else {
        NSLog(@"not linked");
    }
}

- (void)_showSpinner:(BOOL)shouldShow
{
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneTapped:)];
    if (shouldShow) {
        UIActivityIndicatorView *spinner = [UIActivityIndicatorView.alloc initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        [spinner startAnimating];
        
        [self.navigationItem setRightBarButtonItems:@[doneButton, [UIBarButtonItem.alloc initWithCustomView:spinner]] animated:NO];
    } else {
        [self.navigationItem setRightBarButtonItems:@[doneButton] animated:NO];
    }
}


- (void)_showSubDirectory:(DBMetadata *)directoryMetadata
{
    if (!directoryMetadata.isDirectory) {
        return;
    }
    FGDropboxViewController *nextLevelViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"dropboxViewController"];
    nextLevelViewController.subPath = [self.subPath stringByAppendingPathComponent:directoryMetadata.filename];
    nextLevelViewController.title = directoryMetadata.filename;
    [self.navigationController pushViewController:nextLevelViewController animated:YES];
}


- (void)_setSelectSubitemsState
{
    if (self.selectedItems.count > 0) {
        UIBarButtonItem *cancelButton = [UIBarButtonItem.alloc initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(_cancelTapped)];
        [self.navigationItem setRightBarButtonItem:cancelButton animated:NO];
        UIBarButtonItem *downloadButton = [UIBarButtonItem barButtonWithImage:[UIImage imageNamed:@"0107"] style:UIBarButtonItemStylePlain target:self action:@selector(_downloadSelectedItems)];
        [self.navigationItem setLeftBarButtonItem:downloadButton animated:NO];
    } else {
        UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneTapped:)];
        [self.navigationItem setRightBarButtonItem:doneButton animated:NO];
        [self.navigationItem setLeftBarButtonItem:nil animated:NO];
    }
}

#pragma mark - Download manager delegate methods
- (void)downloadManager:(FGDownloadManager *)sender didLoadDirectoryContents:(NSArray *)contents
{
    [self _showSpinner:NO];
    [self.refreshControl endRefreshing];
    self.directoryContents = contents.copy;
}


- (void)downloadManager:(FGDownloadManager *)downloadManager failedLoadingDirectoryContents:(NSError *)error
{
    [self _showSpinner:NO];
    [self.refreshControl endRefreshing];
    NSString *errorMessage = NSLocalizedString(@"Could not connect to Dropbox, is the internet working?", nil);
    [FGHUDMessage showHUDMessage:errorMessage inView:self.view];
}

- (void)downloadManager:(FGDownloadManager *)downloadManager didLoadThumbnail:(DBMetadata *)metadata
{
    NSUInteger tableViewRow = [self.directoryContents indexOfObject:metadata];
    FGDropboxCell *cell = (FGDropboxCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:tableViewRow inSection:0]];
    [self _loadThumbnail:cell.folderFileImage withMetadata:metadata];
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.directoryContents.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Dropbox Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    [self _configureCell:cell withMetaData:self.directoryContents[indexPath.row]];
    return cell;
}


- (void)_loadThumbnail:(UIImageView *)imageView withMetadata:(DBMetadata *)metadata
{
    NSString *fileName = [NSString stringWithFormat:@"%@-%@", metadata.rev, metadata.filename];
    NSString *filePath = [CACHE_DIR stringByAppendingPathComponent:fileName];
    NSFileManager *fileManager = [NSFileManager new];
    if ([fileManager fileExistsAtPath:filePath]) {
        imageView.image = [UIImage imageWithContentsOfFile:filePath];
    } else {
        [FGDownloadManager.sharedInstance.restClient loadThumbnail:metadata.path ofSize:@"75x75_fit_one" intoPath:filePath];
    }
}


- (void)_configureCell:(UITableViewCell *)cell withMetaData:(DBMetadata *)metadata
{
    FGDropboxCell *dropboxCell = (FGDropboxCell *)cell;
    dropboxCell.folderFileName.text = [metadata.filename fitToLength:55];
    
    if (metadata.isDirectory) {
        dropboxCell.folderFileImage.image = [UIImage imageNamed:@"folder_icon"];
        dropboxCell.description.hidden = YES;
    } else {
        NSString *modifiedDuration = [NSString formatInterval:-[metadata.lastModifiedDate timeIntervalSinceNow]];
        dropboxCell.description.hidden = NO;
        dropboxCell.description.text = [metadata.humanReadableSize stringByAppendingString: [@", modified " stringByAppendingString:modifiedDuration]];
        dropboxCell.folderFileImage.image = ([FGMeasurement fileTypeForFileName:metadata.filename] == FGFileTypeUnknown) ? [UIImage imageNamed:@"180-stickynote"] : [UIImage imageNamed:@"flow2go-icon_35"];
    }
    
    if (metadata.thumbnailExists) [self _loadThumbnail:dropboxCell.folderFileImage withMetadata:metadata];
    
    if (self.selectedItems.count == 0) {
        if (!metadata.isDirectory) {
            if ([FGMeasurement fileTypeForFileName:metadata.filename] == FGFileTypeUnknown) {
                dropboxCell.userInteractionEnabled = NO;
                dropboxCell.folderFileName.textColor = [UIColor lightGrayColor];
                dropboxCell.description.textColor = [UIColor lightGrayColor];
            }
        }
    } else {
        if ([self.selectedItems containsObject:metadata]) {
            dropboxCell.accessoryType = UITableViewCellAccessoryCheckmark;
        }
        DBMetadata *primaryItem = self.selectedItems[0];
        if (primaryItem == metadata) {
            dropboxCell.userInteractionEnabled = NO;
        } else if (([FGMeasurement fileTypeForFileName:primaryItem.filename] == FGFileTypeUnknown)
                   || metadata.isDirectory) {
            dropboxCell.userInteractionEnabled = NO;
            dropboxCell.folderFileName.textColor = [UIColor lightGrayColor];
            dropboxCell.description.textColor = [UIColor lightGrayColor];
            dropboxCell.folderFileImage.image = [dropboxCell.folderFileImage.image imageByApplyingAlpha:0.5f];
        }
    }
}


- (void)_togglePresenceInSelectedItems:(DBMetadata *)subItem
{
    if ([self.selectedItems containsObject:subItem]) {
        [self.selectedItems removeObject:subItem];
    } else {
        [self.selectedItems addObject:subItem];
    }
}

#pragma mark - Table view delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    DBMetadata *pickedItem = self.directoryContents[indexPath.row];
    if (self.selectedItems.count == 0) {
        if (pickedItem.isDirectory) {
            [self _showSubDirectory:pickedItem];
        } else {
            [self _selectedFirstFile:self.directoryContents[indexPath.row] atIndexPath:indexPath];
        }
    } else {
        DBMetadata *primaryItem = self.selectedItems[0];
        switch ([FGMeasurement fileTypeForFileName:primaryItem.filename]) {
            case FGFileTypeFCS:
            case FGFileTypeLMD:
                [self _togglePresenceInSelectedItems:pickedItem];
                [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
                break;
            default:
                break;
        }
    }
}


- (void)_selectedFirstFile:(DBMetadata *)primaryItem atIndexPath:(NSIndexPath *)indexPath
{
    if ([FGMeasurement fileTypeForFileName:primaryItem.filename] == FGFileTypeUnknown) {
        return;
    }
    [self.selectedItems addObject:primaryItem];
    [self _setSelectSubitemsState];
    [self.tableView reloadData];
}


- (void)_downloadSelectedItems
{
    [self performSegueWithIdentifier:@"Show Folder Picker" sender:self];

}

#pragma mark - FGFolderPickerTableViewController delegate
- (void)folderPickerTableViewController:(FGFolderPickerTableViewController *)folderPickerTableViewController didPickFolder:(FGFolder *)folder
{
    [FGDownloadManager.sharedInstance downloadFiles:self.selectedItems toFolder:folder];
    [self.selectedItems removeAllObjects];
    [self _setSelectSubitemsState];
    [self.tableView reloadData];
    [self dismissViewControllerAnimated:YES completion:nil];
}


@end
