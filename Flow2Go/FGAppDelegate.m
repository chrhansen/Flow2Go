//
//  AppDelegate.m
//  Flow2Go
//
//  Created by Christian Hansen on 02/08/12.
//  Copyright (c) 2012 Christian Hansen. All rights reserved.
//

#import "FGAppDelegate.h"
#import <DropboxSDK/DropboxSDK.h>
#import "FGStyleController.h"
#import "ATConnect.h"
#import "MSNavigationPaneViewController.h"
#import "FGFolderCollectionViewController.h"

@class FGAnalysisViewController;

@implementation FGAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [TestFlight takeOff:@"043c6b53e9c4be16677615865b03e754_MTMxNDE4MjAxMi0wOS0xMiAxMjo0NzoyMS40ODMwNjg"];
    [MagicalRecord setupCoreDataStackWithStoreNamed:@"Flow2Go.sqlite"];
    DBSession.sharedSession = [DBSession.alloc initWithAppKey:@"jnrnwsyo6j65b4a" appSecret:@"3hlpks700kooxv8" root:kDBRootDropbox];
    ATConnect *connection = [ATConnect sharedConnection];
    connection.apiKey = kApptentiveAPIKey;
    
    // Navigation Pane View Controller
    MSNavigationPaneViewController *navigationPaneViewController = (MSNavigationPaneViewController *)self.window.rootViewController;
    
    // Slave View Controller
    UINavigationController *paneViewController = (UINavigationController *)[navigationPaneViewController.storyboard instantiateViewControllerWithIdentifier:@"analysisViewControllerNavigationController"];
    
    // Master View Controller
    UINavigationController *navigationControllerFolder = (UINavigationController *)[navigationPaneViewController.storyboard instantiateViewControllerWithIdentifier:@"folderNavigationViewController"];
    FGFolderCollectionViewController *folderViewController = (FGFolderCollectionViewController * )navigationControllerFolder.topViewController;
    folderViewController.navigationPaneViewController = navigationPaneViewController;
    [navigationPaneViewController.touchForwardingClasses addObject:[UICollectionView class]];
    navigationPaneViewController.masterViewController = navigationControllerFolder;
    folderViewController.analysisViewController = (FGAnalysisViewController *)paneViewController.topViewController;
    
    [navigationPaneViewController setPaneViewController:paneViewController animated:NO completion:nil];

    [FGStyleController applyAppearance];
    return YES;
}




- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    [NSManagedObjectContext.MR_defaultContext saveToPersistentStoreWithCompletion:nil];
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
    [NSManagedObjectContext.MR_defaultContext saveToPersistentStoreAndWait];
    [MagicalRecord cleanUp];
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url
{
    // Dropbox access URL's
    if ([DBSession.sharedSession handleOpenURL:url]) {
        if (DBSession.sharedSession.isLinked) {
            [NSNotificationCenter.defaultCenter postNotificationName:DropboxLinkedNotification object:nil];
         }
        return YES;
    }
    // Add whatever other url handling code your app requires here
    return NO;
}


@end
