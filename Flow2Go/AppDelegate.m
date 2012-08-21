//
//  AppDelegate.m
//  Flow2Go
//
//  Created by Christian Hansen on 02/08/12.
//  Copyright (c) 2012 Christian Hansen. All rights reserved.
//

#import "AppDelegate.h"
#import "Measurement.h"
#import <DropboxSDK/DropboxSDK.h>


@implementation AppDelegate

- (void)_generateTestData
{
    if ([Measurement MR_countOfEntities] > 0)
        return;
    
    
    // Measurement 1
    Measurement *measurement1 = [Measurement createEntity];
    measurement1.filename = @"fcs file 1.fcs";
    measurement1.lastModificationDate = [NSDate.date dateByAddingTimeInterval:-500];
    measurement1.measurementDate = [NSDate.date dateByAddingTimeInterval:-100000];
    
    // Measurement 2
    Measurement *measurement2 = [Measurement createEntity];
    measurement2.filename = @"fcs file 2.fcs";
    measurement2.lastModificationDate = [NSDate.date dateByAddingTimeInterval:-300];
    measurement2.measurementDate = [NSDate.date dateByAddingTimeInterval:-200000];
    
    // Measurement 3
    Measurement *measurement3 = [Measurement createEntity];
    measurement3.filename = @"fcs file 3.fcs";
    measurement3.lastModificationDate = [NSDate.date dateByAddingTimeInterval:-100];
    measurement3.measurementDate = [NSDate.date dateByAddingTimeInterval:-200000];
    
    [[NSManagedObjectContext MR_defaultContext] MR_save];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [MagicalRecord setupCoreDataStackWithStoreNamed:@"Flow2Go.sqlite"];
    
    //[self _generateTestData];
    
    DBSession *dbSession = [DBSession.alloc initWithAppKey:DropboxAppKey
                                                 appSecret:DropboxAppSecret
                                                      root:kDBRootAppFolder];
    DBSession.sharedSession = dbSession;
    
    // Override point for customization after application launch.
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {

    }
    else
    {

    }
    [self.window makeKeyAndVisible];
    
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    [NSManagedObjectContext.MR_defaultContext MR_save];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    [NSManagedObjectContext.MR_defaultContext MR_save];
    [MagicalRecord cleanUp];
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url
{
    // Dropbox access URL's
    if ([DBSession.sharedSession handleOpenURL:url])
    {
        if (DBSession.sharedSession.isLinked)
        {
            [NSNotificationCenter.defaultCenter postNotificationName:DropboxLinkedNotification
                                                              object:nil];
            NSLog(@"App linked successfully!");
        }
        return YES;
    }
    
    // Add whatever other url handling code your app requires here
    return NO;
}


@end
