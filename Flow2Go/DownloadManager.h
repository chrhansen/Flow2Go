//
//  DownloadManager.h
//  Flow2Go
//
//  Created by Christian Hansen on 02/08/12.
//  Copyright (c) 2012 Christian Hansen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <DropboxSDK/DropboxSDK.h>

@class DownloadManager;

@protocol DownloadManagerDelegate <NSObject>

@optional
- (void)downloadManager:(DownloadManager *)sender didLoadDirectoryContents:(NSArray *)contents;
- (void)downloadManager:(DownloadManager *)sender failedLoadingDirectoryContents:(NSError *)error;
@end

@protocol DownloadManagerProgressDelegate <NSObject>
@optional
- (void)downloadManager:(DownloadManager *)sender loadProgress:(CGFloat)progress forDestinationPath:(NSString *)destinationPath;
@end

@interface DownloadManager : NSObject <DBRestClientDelegate>

+ (DownloadManager *)sharedInstance;

- (void)downloadFile:(DBMetadata *)fileMetadata;

@property (nonatomic, strong) DBRestClient *restClient;
@property (nonatomic, weak) id<DownloadManagerDelegate> delegate;
@property (nonatomic, weak) id<DownloadManagerProgressDelegate> progressDelegate;
@end
