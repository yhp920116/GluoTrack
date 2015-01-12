//
//  AppDelegate+UserLogInOut.m
//  SugarNursing
//
//  Created by Dan on 14-11-6.
//  Copyright (c) 2014年 Tisson. All rights reserved.
//

#import "AppDelegate+UserLogInOut.h"
#import "UIStoryboard+Storyboards.h"
#import "UtilsMacro.h"

@implementation AppDelegate (UserLogInOut)

+ (void)userLogIn
{
    [UIApplication sharedApplication].keyWindow.rootViewController = [[UIStoryboard mainStoryboard] instantiateInitialViewController];
    
}

+ (void)userLogOut
{
    // Delete user loginInfo in CoreData when user logout.
    NSArray *userObjects = [User findAllInContext:[CoreDataStack sharedCoreDataStack].context];
    for (User *user in userObjects) {
        [user deleteEntityInContext:[CoreDataStack sharedCoreDataStack].context];
    }
    [[CoreDataStack sharedCoreDataStack] saveContext];
    
    [UIApplication sharedApplication].keyWindow.rootViewController = [[UIStoryboard loginStoryboard] instantiateInitialViewController];
}

@end
