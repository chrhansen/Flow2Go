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
#define CACHE_DIR [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)  objectAtIndex:0]

#define IS_IPAD (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad)

static NSString * const DropboxBaseURL = @"/";
static NSString * const DropboxLinkedNotification = @"DropboxLinkedNotification";
static NSString * const DropboxFileDownloadedNotification = @"DropboxFileDownloadedNotification";
static NSString * const DropboxFailedDownloadNotification = @"DropboxFailedDownloadNotification";

static NSString * const AnalysisUpdatedNotification = @"AnalysisUpdatedNotification";
extern NSString * const FGHeaderControlsWillAppearNotification;
extern NSString * const FGPickerViewControllerCancelledNotification;

static NSString * const FCSFile_Error_Domain = @"FCSFile_Error_Domain";
static NSString * const FG_FIRST_LAUNCH_KEY = @"FG_FIRST_LAUNCH_KEY";

//Apptentive API-key
#define kApptentiveAPIKey @"054ed3017042a2823a0b7354b8530f1e98457f02307d8b58b23948586f21d082"

//Crashlytics API-key
#define kCrashlyticsAPIKey @"0387772ffe94f1d824a25caa46697d6294cc3f90"

// In-App purchases
extern NSString * const InAppIdentifierFCSFiles;


// Sample File MD5 checksums
extern NSString * const SampleFileCheckSum1;
extern NSString * const SampleFileCheckSum2;

//Dropbox API keys
#define kDropboxAPIKey    @"6hb8rousm8nruan"
#define kDropboxAPISecret @"uapd0yurv7xaev1"

//Pane View Controller
#define PANE_COVER_WIDTH 500.0f
#define PANE_REVEAL_WIDTH 470.0f

// Structs
struct FGEvent
{
	NSUInteger eventNo;
};
typedef struct FGEvent FGEvent;
typedef FGEvent* FGEventPtr;


struct FGPlotPoint
{
    double xVal;
    double yVal;
};
typedef struct FGPlotPoint FGPlotPoint;


struct FGDensityPoint
{
    double xVal;
    double yVal;
    NSUInteger count;
};
typedef struct FGDensityPoint FGDensityPoint;


struct FGRange
{
    double minValue;
    double maxValue;
};
typedef struct FGRange FGRange;


struct FGHistogramPoint
{
    double xVal;
    NSUInteger count;
};
typedef struct FGHistogramPoint FGHistogramPoint;


typedef NS_ENUM(NSInteger, FGGateType)
{
    kGateTypePolygon,
    kGateTypeRectangle,
    kGateTypeSingleRange,
    kGateTypeTripleRange,
    kGateTypeQuadrant,
    kGateTypeEllipse
};

typedef NS_ENUM(NSInteger, FGAxisType)
{
    kAxisTypeUnknown,
    kAxisTypeLinear,
    kAxisTypeLogarithmic
};

typedef NS_ENUM(NSInteger, FGPlotType)
{
    kPlotTypeDot,
    kPlotTypeDensity,
    kPlotTypeHistogram
};

typedef NS_ENUM( NSUInteger, FGFileType ) {
    FGFileTypeUnknown,
    FGFileTypeLMD,
    FGFileTypeFCS
};


typedef NS_ENUM(NSInteger, FGDownloadState)
{
    FGDownloadStateUnknown,
    FGDownloadStateWaiting,
    FGDownloadStateDownloading,
    FGDownloadStateDownloaded,
    FGDownloadStateFailed
};

union _FGVector3
{
    struct
    {
        double x, y, z;
    };
    struct
    {
        double v0, v1, v2;
    };
    
};
typedef union _FGVector3 FGVector3;

union _FGMatrix3
{
    struct
    {
        double m00, m01, m02;
        double m10, m11, m12;
        double m20, m21, m22;
    };
    double m[9];
};
typedef union _FGMatrix3 FGMatrix3;

union _FGEllipseRepresentation
{
    struct
    {
        double a, b;
        double phi;
        double x, y;
    };
    struct
    {
        double halfMajorAxis, halfMinorAxis;
        double rotationCCW;
        double centerX, centerY;
    };
};
typedef union _FGEllipseRepresentation FGEllipseRepresentation;