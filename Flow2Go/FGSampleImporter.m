//
//  FGSampleImporter.m
//  Flow2Go
//
//  Created by Christian Hansen on 12/05/13.
//  Copyright (c) 2013 Christian Hansen. All rights reserved.
//

#import "FGSampleImporter.h"
#import "FGDownloadManager.h"

@implementation FGSampleImporter

+ (void)importSamplesIfFirstLaunch
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (![[defaults valueForKey:FG_FIRST_LAUNCH_KEY] boolValue]) {
        [defaults setValue:[NSNumber numberWithBool:YES] forKey:FG_FIRST_LAUNCH_KEY];
        FGSampleImporter *importer = [[FGSampleImporter alloc] init];
        FGFolder *firstFolder = [importer createFolder];
        [importer createMeasurementsInFolder:firstFolder];
        [defaults synchronize];
    }
}


- (FGFolder *)createFolder
{
    FGFolder *folder = [FGFolder createEntity];
    folder.createdAt = [NSDate date];
    folder.name = NSLocalizedString(@"Sample Files", nil);
    
    return folder;    
}


- (void)createMeasurementsInFolder:(FGFolder *)folder
{
    NSArray *paths = [self sampleFilePaths];
    
    for (NSString *filePath in paths) {
        NSString *newPath = [self copyToDocuments:filePath];
        [[FGDownloadManager sharedInstance] addSkipBackupAttributeToItemAtFilePath:newPath];
        newPath = [@"Documents" stringByAppendingPathComponent:newPath.lastPathComponent];

        FGMeasurement *measurement = [FGMeasurement createEntity];
        measurement.downloadDate = [NSDate date];
        measurement.filename = filePath.lastPathComponent;
        measurement.filePath = newPath;
        measurement.globalURL = nil;
        measurement.md5FileHash = [measurement md5Hash];
        measurement.downloadState = [NSNumber numberWithInteger:FGDownloadStateDownloaded];
        measurement.folder = folder;
        measurement.fGMeasurementID = measurement.md5FileHash;
        [measurement parseFCSKeyWords];
    }
    [folder.managedObjectContext save:nil];
}

- (NSArray *)sampleFilePaths
{
    NSString *filePath1 = [[NSBundle mainBundle] pathForResource:@"Sample-1" ofType:@"lmd"];
    NSString *filePath2 = [[NSBundle mainBundle] pathForResource:@"Sample-2" ofType:@"fcs"];
    NSMutableArray *paths = [NSMutableArray new];
    if (filePath1) [paths addObject:filePath1];
    if (filePath1) [paths addObject:filePath2];
    return paths;
}


- (NSString *)copyToDocuments:(NSString *)fromPath
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    NSString *toPath = [DOCUMENTS_DIR stringByAppendingPathComponent:fromPath.lastPathComponent];
    if ([fileManager fileExistsAtPath:fromPath]) {
        [fileManager copyItemAtPath:fromPath toPath:toPath error:&error];
    }
    return toPath;
}


@end
