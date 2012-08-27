//
//  Constants.h
//  Flow2Go
//
//  Created by Christian Hansen on 02/08/12.
//  Copyright (c) 2012 Christian Hansen. All rights reserved.
//

#import <Foundation/Foundation.h>

#define HOME_DIR [[[NSFileManager.defaultManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask].lastObject path] stringByDeletingLastPathComponent]

#define HOME_URL [[NSFileManager.defaultManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask].lastObject URLByDeletingLastPathComponent]

#define DOCUMENTS_DIR [[NSFileManager.defaultManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask].lastObject path]
#define TEMP_DIR [[[[NSFileManager.defaultManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask].lastObject path] stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"tmp"]

static NSString * const DropboxAppKey = @"9qidbv9e5zj4tsn";
static NSString * const DropboxAppSecret = @"ym32wv0jzsitbba";
static NSString * const DropboxBaseURL = @"/";

static NSString * const DropboxLinkedNotification = @"DropboxLinkedNotification";
static NSString * const DropboxFileDownloadedNotification = @"DropboxFileDownloadedNotification";
static NSString * const DropboxFailedDownloadNotification = @"DropboxFailedDownloadNotification";

static NSString * const AnalysisUpdatedNotification = @"AnalysisUpdatedNotification";

// FCS file specific
#define HEADER_LENGTH 58


// Structs
struct Event
{
	NSUInteger eventNo;
};
typedef struct Event Event;
typedef Event* EventPtr;

struct PlotPoint {
    double x;
    double y;
};
typedef struct PlotPoint PlotPoint;

struct BoundingBox {
    PlotPoint lower;
    PlotPoint upper;
};
typedef struct BoundingBox BoundingBox;

typedef NS_ENUM(NSInteger, GateType)
{
    kGateTypePolygon,
    kGateTypeRectangle,
    kGateTypeRange
};

typedef NS_ENUM(NSInteger, AxisType)
{
    kAxisTypeLinear,
    kAxisTypeLogarithmic,
    kAxisTypeHistogram
};