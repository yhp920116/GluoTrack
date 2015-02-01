//
//  AppDelegate.m
//  SugarNursing
//
//  Created by Dan on 14-11-5.
//  Copyright (c) 2014年 Tisson. All rights reserved.
//

#import "AppDelegate.h"
#import "UIStoryboard+Storyboards.h"
#import "AppDelegate+CustomAppearence.h"
#import "RootViewController.h"
#import <CocoaLumberjack.h>
#import "UtilsMacro.h"
#import "VendorMacro.h"
#import "AppDelegate+UserLogInOut.h"
#import <MobClick.h>


@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    [self configureCustomizing];
    [self configureCocoaLumberjackFramework];
    [self configureUMAnalytics];
    [self configureUserLogin];
    [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:YES];
    // Not to setFrame for UIWindow, it invokes some orientation issues!
    // self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    
    return YES;
}

- (void)configureCustomizing
{
    [[UINavigationBar appearance] setBarTintColor:[UIColor colorWithRed:44/255.0 green:125/255.0 blue:198/255.0 alpha:1]];
    
    NSDictionary *attributes = @{NSForegroundColorAttributeName:[UIColor whiteColor]};
    [[UINavigationBar appearance] setTitleTextAttributes:attributes];
    [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
    [[UINavigationBar appearance] setBarStyle:UIBarStyleBlack];
}

#pragma mark - User Login

- (void)configureUserLogin
{
    // Not User exists.
    if (([[NSString sessionID] isEqualToString:@""] && [[NSString sessionToken] isEqualToString:@""])) {
        self.window.rootViewController = [[UIStoryboard loginStoryboard] instantiateInitialViewController];
        [self.window makeKeyAndVisible];
        return;
    }
    
    self.window.rootViewController = [[UIStoryboard mainStoryboard] instantiateInitialViewController];
    
}

#pragma mark - Application Status

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    [[CoreDataStack sharedCoreDataStack] saveContext];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    // Saves changes in the application's managed object context before the application terminates.
    [[CoreDataStack sharedCoreDataStack] saveContext];
}

#pragma Configure Library Framework

- (void)configureCocoaLumberjackFramework
{
    [DDLog addLogger:[DDASLLogger sharedInstance]];
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
    [[DDTTYLogger sharedInstance] setColorsEnabled:YES];
    
    UIColor *blue = [UIColor colorWithRed:(34/255.0) green:(79/255.0) blue:(188/255.0) alpha:0.8];
    UIColor *green = [UIColor colorWithRed:(27/255.0) green:(152/255.0) blue:(73/255.0) alpha:0.8];
    
    [[DDTTYLogger sharedInstance] setForegroundColor:blue backgroundColor:nil forFlag:DDLogFlagInfo];
    [[DDTTYLogger sharedInstance] setForegroundColor:green backgroundColor:nil forFlag:DDLogFlagDebug];
}

- (void)configureUMAnalytics
{
    NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    [MobClick startWithAppkey:UM_ANALYTICS_KEY reportPolicy:BATCH channelId:nil];
    [MobClick setAppVersion:version];
    [MobClick checkUpdate:NSLocalizedString(@"New Version", nil) cancelButtonTitle:NSLocalizedString(@"Skip", nil) otherButtonTitles:NSLocalizedString(@"Go", nil)];
}




@end
