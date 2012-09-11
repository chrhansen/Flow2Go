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

static NSString * const FCSFile_Error_Domain = @"FCSFile_Error_Domain";


// FCS file specific
#define HEADER_LENGTH 58

// Structs
struct Event
{
	NSUInteger eventNo;
};
typedef struct Event Event;
typedef Event* EventPtr;


struct PlotPoint
{
    double xVal;
    double yVal;
};
typedef struct PlotPoint PlotPoint;


struct DensityPoint
{
    double xVal;
    double yVal;
    NSUInteger count;
};
typedef struct DensityPoint DensityPoint;


struct Range
{
    double minValue;
    double maxValue;
};
typedef struct Range Range;


struct HistogramPoint
{
    double xVal;
    NSUInteger count;
};
typedef struct HistogramPoint HistogramPoint;


typedef NS_ENUM(NSInteger, GateType)
{
    kGateTypePolygon,
    kGateTypeRectangle,
    kGateTypeSingleRange,
    kGateTypeTripleRange,
    kGateTypeQuadrant,
    kGateTypeEllipse
};

typedef NS_ENUM(NSInteger, AxisType)
{
    kAxisTypeUnknown,
    kAxisTypeLinear,
    kAxisTypeLogarithmic
};

typedef NS_ENUM(NSInteger, PlotType)
{
    kPlotTypeDot,
    kPlotTypeDensity,
    kPlotTypeHistogram
};