//
//  DownloadManager.h
//  Flow2Go
//
//  Created by Christian Hansen on 02/08/12.
//  Copyright (c) 2012 Christian Hansen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <DropboxSDK/DropboxSDK.h>

@class FGDownloadManager;
@class FGFolder, FGMeasurement;

@protocol FGDownloadManagerDelegate <NSObject>

@optional
- (void)downloadManager:(FGDownloadManager *)downloadManager didLoadDirectoryContents:(NSArray *)contents;
- (void)downloadManager:(FGDownloadManager *)downloadManager failedLoadingDirectoryContents:(NSError *)error;
- (void)downloadManager:(FGDownloadManager *)downloadManager didLoadThumbnail:(DBMetadata *)metadata;
@end

@protocol FGDownloadManagerProgressDelegate <NSObject>
@optional
- (void)downloadManager:(FGDownloadManager *)downloadManager beganDownloadingMeasurement:(FGMeasurement *)measurement;
- (void)downloadManager:(FGDownloadManager *)downloadManager loadProgress:(CGFloat)progress forMeasurement:(FGMeasurement *)measurement;
- (void)downloadManager:(FGDownloadManager *)downloadManager finishedDownloadingMeasurement:(FGMeasurement *)measurement;
- (void)downloadManager:(FGDownloadManager *)downloadManager failedDownloadingMeasurement:(FGMeasurement *)measurement;
@end

@interface FGDownloadManager : NSObject <DBRestClientDelegate>

+ (FGDownloadManager *)sharedInstance;
- (void)downloadFiles:(NSArray *)files toFolder:(FGFolder *)folder;
- (void)downloadFile:(DBMetadata *)fileMetadata toFolder:(FGFolder *)folder;
- (void)retryDownloadOfMeasurement:(FGMeasurement *)measurement;

@property (nonatomic, strong) DBRestClient *restClient;
@property (nonatomic, weak) id<FGDownloadManagerDelegate> delegate;
@property (nonatomic, weak) id<FGDownloadManagerProgressDelegate> progressDelegate;
@end
