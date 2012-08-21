//
//  DropboxViewController.m
//  Flow2Go
//
//  Created by Christian Hansen on 02/08/12.
//  Copyright (c) 2012 Christian Hansen. All rights reserved.
//

#import "DropboxViewController.h"
#import "DownloadManager.h"

@interface DropboxViewController () <DownloadManagerDelegate>

@property (nonatomic, strong) NSArray *directoryContents;

@end

@implementation DropboxViewController

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

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    [self _addBarButtons];
    
    [self _addObservers];
    
    self.directoryContents = @[];
    
    if (!self.subPath)
    {
        self.subPath = @"";
        self.title = @"Dropbox";
    }
    
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (!DBSession.sharedSession.isLinked)
    {
        [DBSession.sharedSession linkFromController:self];
    }
    else
    {
        [self _requestFolderList];
    }
    
}

- (void)viewDidUnload
{
    [NSNotificationCenter.defaultCenter removeObserver:self];
    [super viewDidUnload];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)doneTapped
{
    [self dismissViewControllerAnimated:YES completion:nil];
}


- (void)_addBarButtons
{
    UIBarButtonItem *doneButton = [UIBarButtonItem.alloc initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                target:self
                                                                                action:@selector(doneTapped)];
    self.navigationItem.rightBarButtonItem = doneButton;
    
}


- (void)_addObservers
{
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(_requestFolderList)
                                               name:DropboxLinkedNotification
                                             object:nil];
}


- (void)_requestFolderList
{
    if (DBSession.sharedSession.isLinked)
    {
        DownloadManager.sharedInstance.delegate = self;
        [DownloadManager.sharedInstance.restClient loadMetadata:[DropboxBaseURL stringByAppendingPathComponent:self.subPath]];
    }
    else
    {
        NSLog(@"not linked");
    }
}

#pragma mark - Download manager delegate methods
- (void)downloadManager:(DownloadManager *)sender didLoadDirectoryContents:(NSArray *)contents
{
    self.directoryContents = contents.copy;
    [self.tableView reloadData];
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
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier
                                                            forIndexPath:indexPath];
    
    [self _configureCell:cell withMetaData:self.directoryContents[indexPath.row]];
    
    return cell;
}

- (void)_configureCell:(UITableViewCell *)cell withMetaData:(DBMetadata *)metadata
{
    cell.textLabel.text = metadata.filename;
    if (metadata.isDirectory)
    {
        cell.detailTextLabel.text = nil;
    }
    else
    {
        cell.detailTextLabel.text = metadata.lastModifiedDate.description;
    }
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    DBMetadata *pickedItem = self.directoryContents[indexPath.row];
    if (pickedItem.isDirectory)
    {
        DropboxViewController *nextLevelViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"dropboxViewController"];
        nextLevelViewController.subPath = [self.subPath stringByAppendingPathComponent:pickedItem.filename];
        nextLevelViewController.title = pickedItem.filename;
        [self.navigationController pushViewController:nextLevelViewController animated:YES];
    }
    else
    {
        [DownloadManager.sharedInstance downloadFile:self.directoryContents[indexPath.row]];
    }
}

@end
