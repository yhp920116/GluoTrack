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
#import "UMessage.h"


@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    [self configureCustomizing];
    [self configureCocoaLumberjackFramework];
    [self configureUMAnalytics];
    [self configureUMAPNS:launchOptions];
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

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    [UMessage registerDeviceToken:deviceToken];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    [UMessage didReceiveRemoteNotification:userInfo];
}

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

- (void)configureUMAPNS:(NSDictionary *)launchOptions
{
    [UMessage startWithAppkey:UM_MESSAGE_APPKEY launchOptions:launchOptions];
    
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= _IPHONE80_
    if(UMSYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0"))
    {
        //register remoteNotification types
        UIMutableUserNotificationAction *action1 = [[UIMutableUserNotificationAction alloc] init];
        action1.identifier = @"action1_identifier";
        action1.title=@"Accept";
        action1.activationMode = UIUserNotificationActivationModeForeground;//当点击的时候启动程序
        
        UIMutableUserNotificationAction *action2 = [[UIMutableUserNotificationAction alloc] init];  //第二按钮
        action2.identifier = @"action2_identifier";
        action2.title=@"Reject";
        action2.activationMode = UIUserNotificationActivationModeBackground;//当点击的时候不启动程序，在后台处理
        action2.authenticationRequired = YES;//需要解锁才能处理，如果action.activationMode = UIUserNotificationActivationModeForeground;则这个属性被忽略；
        action2.destructive = YES;
        
        UIMutableUserNotificationCategory *categorys = [[UIMutableUserNotificationCategory alloc] init];
        categorys.identifier = @"category1";//这组动作的唯一标示
        [categorys setActions:@[action1,action2] forContext:(UIUserNotificationActionContextDefault)];
        
        UIUserNotificationSettings *userSettings = [UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeBadge|UIUserNotificationTypeSound|UIUserNotificationTypeAlert
                                                                                     categories:[NSSet setWithObject:categorys]];
        [UMessage registerRemoteNotificationAndUserNotificationSettings:userSettings];
        
    } else{
        //register remoteNotification types
        [UMessage registerForRemoteNotificationTypes:UIRemoteNotificationTypeBadge
         |UIRemoteNotificationTypeSound
         |UIRemoteNotificationTypeAlert];
    }
#else
    
    //register remoteNotification types
    [UMessage registerForRemoteNotificationTypes:UIRemoteNotificationTypeBadge
     |UIRemoteNotificationTypeSound
     |UIRemoteNotificationTypeAlert];
    
#endif
    
    //for log
    [UMessage setLogEnabled:YES];
    [UMessage setAutoAlert:NO];

}


@end
