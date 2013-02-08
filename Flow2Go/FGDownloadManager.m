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
#import "FGFolder+Management.h"

@interface FGDownloadManager ()

@property (nonatomic, strong) NSMutableDictionary *currentDownloads;
@property (nonatomic, strong) NSMutableDictionary *sharableLinks;
@property (nonatomic, strong) NSMutableDictionary *errorDownloads;

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

- (NSMutableDictionary *)sharableLinks
{
    if (_sharableLinks == nil) {
        _sharableLinks = [NSMutableDictionary dictionary];
    }
    return _sharableLinks;
}

- (NSMutableDictionary *)errorDownloads
{
    if (_errorDownloads == nil) {
        _errorDownloads = [NSMutableDictionary dictionary];
    }
    return _errorDownloads;
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
    if (measurement.isDownloaded) {
        self.sharableLinks[metadata.path] = measurement;
        [self.restClient loadSharableLinkForFile:metadata.path shortUrl:YES];
        return;
    }
    NSError *error;
    NSString *directoryPath = [@"tmp" stringByAppendingPathComponent:[NSString getUUID]];
    [NSFileManager.defaultManager createDirectoryAtPath:[HOME_DIR stringByAppendingPathComponent:directoryPath] withIntermediateDirectories:NO attributes:nil error:&error];
    if (error) {
        NSLog(@"Error: %@", error.localizedDescription);
        return;
    }
    NSString *relativePath = [directoryPath stringByAppendingPathComponent:metadata.filename];
    NSDictionary *objectDetails = @{@"metadata" : metadata,
                                    @"filePath" : relativePath,
                                    @"downloadDate": NSDate.date};
    FGMeasurement *newMeasurement = [[FGMeasurement MR_importFromArray:@[objectDetails]] lastObject];
    newMeasurement.folder = folder;
    self.sharableLinks[metadata.path] = newMeasurement;
    [self.restClient loadSharableLinkForFile:metadata.path shortUrl:YES];
    if (!newMeasurement.isDownloaded) {
        NSString *destinationPath = [HOME_DIR stringByAppendingPathComponent:relativePath];
        NSAssert(newMeasurement, @"Failed importing fcsfile based on dictionary");
        self.currentDownloads[destinationPath] = newMeasurement;
        [self.restClient loadFile:metadata.path intoPath:destinationPath];
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
- (void)restClient:(DBRestClient*)client loadedFile:(NSString*)destPath contentType:(NSString*)contentType metadata:(DBMetadata*)metadata
{
    FGMeasurement *measurementDownloaded = self.currentDownloads[destPath];
    if (measurementDownloaded) {
        [self.currentDownloads removeObjectForKey:destPath];
        [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
            NSString *newRelativePath = [self moveToDocumentsAndAvoidBackup:destPath];
            NSDictionary *objectDetails = @{@"metadata" : metadata, @"filePath" : newRelativePath};
            [FGMeasurement importFromArray:@[objectDetails] inContext:localContext];
        } completion:^(BOOL success, NSError *error) {
            NSAssert([NSThread isMainThread], @"Import callback not on main thread");
            [NSNotificationCenter.defaultCenter postNotificationName:DropboxFileDownloadedNotification object:nil userInfo:@{@"metadata" : metadata}];
            if ([self.progressDelegate respondsToSelector:@selector(downloadManager:finishedDownloadingModel:)]) {
                [self.progressDelegate downloadManager:self finishedDownloadingMeasurement:measurementDownloaded];
            }
        }];
    }
}


- (void)restClient:(DBRestClient*)client loadFileFailedWithError:(NSError*)error
{
    //TODO: find the failed download file and remove from [self.currentDownloads removeObjectForKey:destPath];
    NSString *destinationPath = error.userInfo[@"destinationPath"];
    NSString *sourcePath = error.userInfo[@"path"];
    if (destinationPath
        && sourcePath)
    {
        if (!self.errorDownloads[sourcePath]) {
            // try an extra time to download the file
            [self.errorDownloads setValue:destinationPath forKey:sourcePath];
            [self.restClient loadFile:sourcePath intoPath:destinationPath];
        } else {
            // one additional attempt has been done already
            [self.errorDownloads removeObjectForKey:sourcePath];
        }
    }
    else if ([self.progressDelegate respondsToSelector:@selector(downloadManager:failedDownloadingModel:)]) {
        [self.progressDelegate downloadManager:self failedDownloadingModel:nil];
        [NSNotificationCenter.defaultCenter postNotificationName:DropboxFailedDownloadNotification object:nil userInfo:@{@"error" : error}];
    }
}


- (void)restClient:(DBRestClient*)client loadProgress:(CGFloat)progress forFile:(NSString*)destPath
{
    NSAssert([NSThread isMainThread], @"Download progress not called on Main Thread");
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

- (NSString *)moveToDocumentsAndAvoidBackup:(NSString *)filePath
{
    NSFileManager *fileManager = NSFileManager.defaultManager;
    NSError *error;
    NSString *relativePath = @"Documents";
    if ([fileManager fileExistsAtPath:filePath]) {
        NSArray *components = filePath.pathComponents;
        if (components.count > 1) relativePath = [@"Documents" stringByAppendingPathComponent:components[components.count - 2]];
        NSString *enclosingDirectory = filePath.stringByDeletingLastPathComponent;
        
        if ([fileManager moveItemAtPath:enclosingDirectory toPath:[HOME_DIR stringByAppendingPathComponent:relativePath] error:&error]) {
            [self addSkipBackupAttributeToItemAtFilePath:[HOME_DIR stringByAppendingPathComponent:relativePath]];
        } else {
            NSLog(@"Error moving file to doc-dir: %@, error %@", filePath, error);
        }
    }
    return [relativePath stringByAppendingPathComponent:filePath.lastPathComponent];
}

#pragma mark - Skip Back-Up Attribute
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
