//
//  DownloadManager.m
//  Flow2Go
//
//  Created by Christian Hansen on 02/08/12.
//  Copyright (c) 2012 Christian Hansen. All rights reserved.
//

#import "DownloadManager.h"
#import "Measurement.h"

@implementation DownloadManager

+ (DownloadManager *)sharedInstance
{
    static DownloadManager *downloadManager = nil;
	if (downloadManager == nil)
	{
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^ {
                          downloadManager = [[DownloadManager alloc] init];
                      });
	}
	
	return downloadManager;
}


- (id)init
{
    self = [super init];
    if (self)
    {

    }
    return self;
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
    NSString *targetPath = [DOCUMENTS_DIR stringByAppendingPathComponent:fileMetadata.filename];
    [Measurement createWithDictionary:@{
    @"metadata" : fileMetadata ,
    @"filepath" : targetPath}];
    [NSManagedObjectContext.MR_defaultContext MR_save];
    [self.restClient loadFile:fileMetadata.path intoPath:targetPath];

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
    
    [Measurement createWithDictionary:@{
     @"metadata" : metadata ,
     @"dateDownloaded": NSDate.date ,
     @"filepath" : [DOCUMENTS_DIR stringByAppendingPathComponent:destPath.lastPathComponent]}];
    [NSManagedObjectContext.MR_defaultContext MR_saveInBackgroundCompletion:^{
        
        NSLog(@"completed saving \"%@\"", metadata.filename);
        
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


@end
