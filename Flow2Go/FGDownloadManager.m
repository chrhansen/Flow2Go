//
//  DownloadManager.m
//  Flow2Go
//
//  Created by Christian Hansen on 02/08/12.
//  Copyright (c) 2012 Christian Hansen. All rights reserved.
//

#import "FGDownloadManager.h"
#import "FGMeasurement+Management.h"
#import "NSString+UUID.h"
#import "FGFolder.h"

@interface FGDownloadManager ()

@property (nonatomic, strong) NSMutableDictionary *currentDownloads;
@property (nonatomic, strong) NSMutableDictionary *sharableLinks;
@property (nonatomic, strong) NSMutableDictionary *downloadProgresses;

@end

@implementation FGDownloadManager

+ (FGDownloadManager *)sharedInstance
{
    static FGDownloadManager *_downloadManager = nil;
	if (_downloadManager == nil) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            _downloadManager = [FGDownloadManager.alloc init];
        });
	}
    return _downloadManager;
}


- (DBRestClient *)restClient
{
    if (!_restClient) {
        _restClient = [DBRestClient.alloc initWithSession:DBSession.sharedSession];
        _restClient.delegate = self;
    }
    return _restClient;
}


- (NSMutableDictionary *)currentDownloads
{
    if (_currentDownloads == nil) {
        _currentDownloads = [NSMutableDictionary dictionary];
    }
    return _currentDownloads;
}


- (NSMutableDictionary *)downloadProgresses
{
    if (_downloadProgresses == nil) {
        _downloadProgresses = [NSMutableDictionary new];
    }
    return _downloadProgresses;
}

- (NSMutableDictionary *)sharableLinks
{
    if (_sharableLinks == nil) {
        _sharableLinks = [NSMutableDictionary dictionary];
    }
    return _sharableLinks;
}


- (void)downloadFiles:(NSArray *)files toFolder:(FGFolder *)folder
{
    for (DBMetadata *fcsFile in files) {
        [self downloadFile:fcsFile toFolder:folder];
    }
}

- (void)downloadFile:(DBMetadata *)metadata toFolder:(FGFolder *)folder
{
    FGMeasurement *measurement = [FGMeasurement findFirstByAttribute:@"fGMeasurementID" withValue:metadata.rev];
    if ([measurement state] == FGDownloadStateDownloaded) {
        self.sharableLinks[metadata.path] = measurement;
        [self.restClient loadSharableLinkForFile:metadata.path shortUrl:YES];
        return;
    }
    NSError *error;
    NSString *directoryPath = [@"tmp" stringByAppendingPathComponent:[NSString getUUID]];
    [[NSFileManager defaultManager] createDirectoryAtPath:[HOME_DIR stringByAppendingPathComponent:directoryPath] withIntermediateDirectories:NO attributes:nil error:&error];
    if (error) {
        NSLog(@"Error: %@", error.localizedDescription);
        return;
    }
    NSString *relativePath = [directoryPath stringByAppendingPathComponent:metadata.filename];
    NSManagedObjectID *folderID = [folder objectID];
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        NSDictionary *objectDetails = @{@"metadata"    : metadata,
                                        @"filePath"    : relativePath,
                                        @"downloadDate": NSDate.date,
                                        @"globalURL"   : metadata.path};
        FGMeasurement *newMeasurement = [[FGMeasurement MR_importFromArray:@[objectDetails] inContext:localContext] lastObject];
        FGFolder *localFolder = (FGFolder *)[localContext objectWithID:folderID];
        newMeasurement.folder = localFolder;
    } completion:^(BOOL success, NSError *error){
        FGMeasurement *newMeasurement = [FGMeasurement findFirstByAttribute:@"fGMeasurementID" withValue:metadata.rev];
        if ([newMeasurement state] != FGDownloadStateDownloaded) {
            NSAssert(newMeasurement, @"Failed importing fcsfile based on dictionary");
            [self _downloadMeasurement:newMeasurement];
        }
    }];
}


- (void)refreshDownloadStates
{
    NSArray *measurements = [FGMeasurement findAllSortedBy:@"downloadDate" ascending:YES withPredicate:[NSPredicate predicateWithFormat:@"downloadState != %@", [NSNumber numberWithInteger:FGDownloadStateDownloaded]]];
    for (FGMeasurement *measurement in measurements) {
        if ([measurement.filePath hasPrefix:@"Documents"]) {
            [measurement setState:FGDownloadStateDownloaded];
            if (!measurement.md5FileHash) measurement.md5FileHash = [measurement md5Hash];
            
            if (measurement.globalURL && ![measurement.globalURL hasPrefix:@"http://"]) {
                self.sharableLinks[measurement.globalURL] = measurement;
                [self.restClient loadSharableLinkForFile:measurement.globalURL shortUrl:YES];
            }
        } else if ([measurement state] == FGDownloadStateDownloading) {
            if (![self.currentDownloads.allValues containsObject:measurement]) [measurement setState:FGDownloadStateFailed];
        } else if ([measurement state] == FGDownloadStateUnknown) {
            [measurement setState:FGDownloadStateFailed];
        }
    }
}

- (void)retryFailedDownload:(FGMeasurement *)measurement
{
    if ([measurement state] != FGDownloadStateFailed) {
        return; //File is already downloaded, waiting, or currently loading (or object is nil)
    }
    [self _downloadMeasurement:measurement];
}


- (void)_downloadMeasurement:(FGMeasurement *)measurement
{
    if (!measurement) return;
    
    [measurement setState:FGDownloadStateWaiting];
    self.currentDownloads[measurement.fullFilePath] = measurement;
    self.downloadProgresses[measurement.fGMeasurementID] = @0.0F;
    [self.restClient loadFile:measurement.globalURL intoPath:measurement.fullFilePath];
    [measurement setState:FGDownloadStateDownloading];
    if ([self.progressDelegate respondsToSelector:@selector(downloadManager:beganDownloadingMeasurement:)]) {
        [self.progressDelegate downloadManager:self beganDownloadingMeasurement:measurement];
    }
}


#pragma mark - Dropbox Delegate methods
#pragma mark Load directory contents

- (void)restClient:(DBRestClient *)client loadedMetadata:(DBMetadata *)metadata
{
    if (metadata.isDirectory) {
        if ([self.delegate respondsToSelector:@selector(downloadManager:didLoadDirectoryContents:)]) {
            [self.delegate downloadManager:self didLoadDirectoryContents:metadata.contents];
        }
    }
}


- (void)restClient:(DBRestClient *)client loadMetadataFailedWithError:(NSError *)error
{
    if ([self.delegate respondsToSelector:@selector(downloadManager:failedLoadingDirectoryContents:)]) {
        [self.delegate downloadManager:self failedLoadingDirectoryContents:error];
    }
}


#pragma mark Download callbacks
- (void)restClient:(DBRestClient*)client loadedFile:(NSString*)destPath contentType:(NSString*)contentType metadata:(DBMetadata *)metadata
{
    FGMeasurement *measurementDownloaded = self.currentDownloads[destPath];
    [measurementDownloaded setState:FGDownloadStateDownloaded];
    if (measurementDownloaded) {
        [self.currentDownloads removeObjectForKey:destPath];
        [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
            NSString *newRelativePath = [self moveToDocuments:destPath];
            [self addSkipBackupAttributeToItemAtFilePath:[HOME_DIR stringByAppendingPathComponent:newRelativePath]];
            NSDictionary *objectDetails = @{@"metadata" : metadata,
                                            @"filePath" : newRelativePath,
                                            @"downloadDate": [NSDate date]};
            FGMeasurement *measurement = [FGMeasurement importFromArray:@[objectDetails] inContext:localContext].lastObject;
            [measurement setState:FGDownloadStateDownloaded];
            [measurement parseFCSKeyWords];
            measurement.md5FileHash = [measurement md5Hash];
        } completion:^(BOOL success, NSError *error) {
            NSAssert([NSThread isMainThread], @"Import callback not on main thread");
            [self.downloadProgresses removeObjectForKey:measurementDownloaded.fGMeasurementID];
            self.sharableLinks[metadata.path] = measurementDownloaded;
            [self.restClient loadSharableLinkForFile:metadata.path shortUrl:YES];
            [NSNotificationCenter.defaultCenter postNotificationName:DropboxFileDownloadedNotification object:nil userInfo:@{@"metadata" : metadata}];
            if ([self.progressDelegate respondsToSelector:@selector(downloadManager:finishedDownloadingMeasurement:)]) {
                [self.progressDelegate downloadManager:self finishedDownloadingMeasurement:measurementDownloaded];
            }
            if (error) {
                NSLog(@"Error saving downloaded measurement: %@", error.localizedDescription);
            }
        }];
    }
}


- (void)restClient:(DBRestClient*)client loadFileFailedWithError:(NSError*)error
{
    //TODO: find the failed download file and remove from [self.currentDownloads removeObjectForKey:destPath];
    NSString *destinationPath = error.userInfo[@"destinationPath"];
    NSString *sourcePath = error.userInfo[@"path"];

    FGMeasurement *measurement = self.currentDownloads[destinationPath];
    [measurement setState:FGDownloadStateFailed];
    [self.currentDownloads removeObjectForKey:sourcePath];
    [self.downloadProgresses removeObjectForKey:measurement.fGMeasurementID];
    [NSNotificationCenter.defaultCenter postNotificationName:DropboxFailedDownloadNotification object:nil userInfo:@{@"error" : error}];
    if ([self.progressDelegate respondsToSelector:@selector(downloadManager:failedDownloadingMeasurement:)]) {
        [self.progressDelegate downloadManager:self failedDownloadingMeasurement:measurement];
    }
}


- (void)restClient:(DBRestClient*)client loadProgress:(CGFloat)progress forFile:(NSString*)destPath
{
    NSAssert([NSThread isMainThread], @"Download progress not called on Main Thread");
    FGMeasurement *measurement = self.currentDownloads[destPath];
    if (!measurement) {
        return;
    }
    self.downloadProgresses[measurement.fGMeasurementID] = [NSNumber numberWithFloat:progress];
    if ([self.progressDelegate respondsToSelector:@selector(downloadManager:loadProgress:forMeasurement:)])
        [self.progressDelegate downloadManager:self loadProgress:progress forMeasurement:self.currentDownloads[destPath]];
}

#pragma mark Thumbnails
- (void)restClient:(DBRestClient*)client loadedThumbnail:(NSString*)destPath metadata:(DBMetadata*)metadata
{
    if ([self.delegate respondsToSelector:@selector(downloadManager:didLoadThumbnail:)]) {
        [self.delegate downloadManager:self didLoadThumbnail:metadata];
    }
}


#pragma mark Sharable Links
- (void)restClient:(DBRestClient *)restClient loadedSharableLink:(NSString *)link forFile:(NSString *)path
{
    FGMeasurement *measurement = self.sharableLinks[path];
    measurement.globalURL = link;
    [self.sharableLinks removeObjectForKey:path];
}

- (void)restClient:(DBRestClient *)restClient loadSharableLinkFailedWithError:(NSError *)error
{
    NSLog(@"Error loading sharable link: %@", [error localizedDescription]);
}


#pragma mark - Local file operations

- (NSString *)moveToDocuments:(NSString *)filePath
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    NSString *relativePath = @"Documents";
    if ([fileManager fileExistsAtPath:filePath]) {
        NSArray *components = filePath.pathComponents;
        if (components.count > 1) relativePath = [@"Documents" stringByAppendingPathComponent:components[components.count - 2]];
        NSString *enclosingDirectory = filePath.stringByDeletingLastPathComponent;
        [fileManager moveItemAtPath:enclosingDirectory toPath:[HOME_DIR stringByAppendingPathComponent:relativePath] error:&error];
    }
    return [relativePath stringByAppendingPathComponent:filePath.lastPathComponent];
}

#pragma mark Skip Back-Up Attribute
- (BOOL)addSkipBackupAttributeToItemAtFilePath:(NSString *)filePath
{
    NSURL *URL = [NSURL fileURLWithPath:filePath];
    assert([NSFileManager.defaultManager fileExistsAtPath:URL.path]);
    
    NSError *error = nil;
    BOOL success = [URL setResourceValue:[NSNumber numberWithBool:YES] forKey: NSURLIsExcludedFromBackupKey error:&error];
    if(!success) NSLog(@"Error excluding %@ from backup %@", [URL lastPathComponent], error);
    
    return success;
}


@end
