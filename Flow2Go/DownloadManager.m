//
//  DownloadManager.m
//  Flow2Go
//
//  Created by Christian Hansen on 02/08/12.
//  Copyright (c) 2012 Christian Hansen. All rights reserved.
//

#import "DownloadManager.h"
#import "Measurement.h"
#import "NSString+UUID.h"
#import "Folder.h"

@implementation DownloadManager

+ (DownloadManager *)sharedInstance
{
    static DownloadManager *downloadManager = nil;
	if (downloadManager == nil)
	{
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^
                      {
                          downloadManager = [DownloadManager.alloc init];
                      });
	}
    return downloadManager;
}


- (DBRestClient *)restClient
{
    if (!_restClient)
    {
        _restClient = [DBRestClient.alloc initWithSession:DBSession.sharedSession];
        _restClient.delegate = self;
    }
    return _restClient;
}

- (void)downloadFile:(DBMetadata *)fileMetadata
{
    NSString *uniqueID = [NSString getUUID];
    NSString *relativePath = [@"tmp" stringByAppendingPathComponent:[uniqueID stringByAppendingPathExtension:fileMetadata.filename.pathExtension]];

    [Measurement createWithDictionary:@{
     @"metadata" : fileMetadata,
     @"filepath" : relativePath,
     @"uniqueID" : uniqueID } inContext:nil];
    [NSManagedObjectContext.MR_defaultContext MR_save];
    [self.restClient loadFile:fileMetadata.path intoPath:[HOME_DIR stringByAppendingPathComponent:relativePath]];
}

- (void)downloadFile:(DBMetadata *)fileMetadata toFolder:(Folder *)folder;
{
    NSString *uniqueID = [NSString getUUID];
    NSString *relativePath = [@"tmp" stringByAppendingPathComponent:[uniqueID stringByAppendingPathExtension:fileMetadata.filename.pathExtension]];
    
    Measurement *newMeasurement = [Measurement createWithDictionary:@{
     @"metadata" : fileMetadata,
     @"filepath" : relativePath,
     @"uniqueID" : uniqueID } inContext:folder.managedObjectContext];
    newMeasurement.folder = folder;
    [folder.managedObjectContext save];

    [self.restClient loadFile:fileMetadata.path intoPath:[HOME_DIR stringByAppendingPathComponent:relativePath]];
}

#pragma mark - Dropbox Delegate methods
#pragma mark Load directory contents

- (void)restClient:(DBRestClient *)client loadedMetadata:(DBMetadata *)metadata
{
    if (metadata.isDirectory)
    {
        if ([self.delegate respondsToSelector:@selector(downloadManager:didLoadDirectoryContents:)])
        {
            [self.delegate downloadManager:self didLoadDirectoryContents:metadata.contents];
        }
    }
}

- (void)restClient:(DBRestClient *)client loadMetadataFailedWithError:(NSError *)error
{
    if ([self.delegate respondsToSelector:@selector(downloadManager:failedLoadingDirectoryContents:)])
    {
        [self.delegate downloadManager:self failedLoadingDirectoryContents:error];
    }
}

#pragma mark Download callbacks
- (void)restClient:(DBRestClient*)client
        loadedFile:(NSString*)destPath
       contentType:(NSString*)contentType
          metadata:(DBMetadata*)metadata
{
    [NSNotificationCenter.defaultCenter postNotificationName:DropboxFileDownloadedNotification
                                                      object:nil
                                                    userInfo:@{@"metadata" : metadata}];
    NSString *newRelativePath = [self moveToDocumentsAndAvoidBackup:destPath];
    
    [Measurement createWithDictionary:@{
     @"metadata" : metadata ,
     @"downloadDate": NSDate.date ,
     @"filepath" : newRelativePath,
     @"uniqueID" : newRelativePath.lastPathComponent.stringByDeletingPathExtension} inContext:nil];
    [NSManagedObjectContext.MR_defaultContext MR_saveInBackgroundCompletion:^{
    }];
}

- (void)restClient:(DBRestClient*)client loadFileFailedWithError:(NSError*)error
{
    [NSNotificationCenter.defaultCenter postNotificationName:DropboxFailedDownloadNotification
                                                      object:nil
                                                    userInfo:@{@"error" : error}];
}

- (void)restClient:(DBRestClient*)client loadProgress:(CGFloat)progress forFile:(NSString*)destPath
{
    if ([self.progressDelegate respondsToSelector:@selector(downloadManager:loadProgress:forDestinationPath:)])
    {
        [self.progressDelegate downloadManager:self loadProgress:progress forDestinationPath:destPath];
    }
}


- (NSString *)moveToDocumentsAndAvoidBackup:(NSString *)filePath
{
    NSFileManager *fileManager = NSFileManager.defaultManager;
    NSError *error = nil;
    NSString *relativePath = nil;
    if ([fileManager fileExistsAtPath:filePath])
    {
        relativePath = [@"Documents" stringByAppendingPathComponent:filePath.lastPathComponent];
        BOOL succes = [fileManager moveItemAtPath:filePath toPath:[HOME_DIR stringByAppendingPathComponent:relativePath] error:&error];
        
        if (succes)
        {
            [self addSkipBackupAttributeToItemAtFilePath:[HOME_DIR stringByAppendingPathComponent:relativePath]];
        }
        else
        {
            NSLog(@"Error moving file to doc-dir: %@, error %@", filePath, error);
        }
    }
    return relativePath;
}

#pragma mark - Skip Back-Up Attribute
- (BOOL)addSkipBackupAttributeToItemAtFilePath:(NSString *)filePath
{
    NSURL *URL = [NSURL fileURLWithPath:filePath];
    assert([NSFileManager.defaultManager fileExistsAtPath:URL.path]);
    
    NSError *error = nil;
    BOOL success = [URL setResourceValue: [NSNumber numberWithBool: YES]
                                  forKey: NSURLIsExcludedFromBackupKey error: &error];
    if(!success){
        NSLog(@"Error excluding %@ from backup %@", [URL lastPathComponent], error);
    }
    return success;
}



@end
