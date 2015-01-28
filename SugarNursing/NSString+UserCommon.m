//
//  NSString+UserCommon.m
//  SugarNursing
//
//  Created by Dan on 14-12-27.
//  Copyright (c) 2014年 Tisson. All rights reserved.
//

#import "NSString+UserCommon.h"
#import "UtilsMacro.h"

@implementation NSString (UserCommon)

+ (User *)fetchUser
{
    NSArray *userObjects = [User findAllInContext:[CoreDataStack sharedCoreDataStack].context];
    if ([userObjects count] == 0) {
        DDLogDebug(@"No User Exists");
        return nil;
    }
    User *user = userObjects[0];
    return user;

}

+ (UserInfo *)fetchUserInfo
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"userid.userId = %@ && userid.linkManId = %@",[NSString userID],[NSString linkmanID]];
    NSArray *userInfoObjects = [UserInfo findAllWithPredicate:predicate inContext:[CoreDataStack sharedCoreDataStack].context];
    
    if (userInfoObjects.count == 0) {
        DDLogInfo(@"NO UserInfo Exists");
        return nil;
    }
    
    UserInfo *userInfo = userInfoObjects[0];
    return userInfo;
}

+ (NSString *)userID
{
    User *user = [self fetchUser];
    if (!user) {
        return @"";
    }
    return user.userId ? user.userId : @"";
}

+ (NSString *)linkmanID
{
    User *user = [self fetchUser];
    if (!user) {
        return @"";
    }
    return user.linkManId ? user.linkManId : @"";
}

+ (NSString *)sessionID
{
    User *user = [self fetchUser];
    if (!user) {
        return @"";
    }
    return user.sessionId ? user.sessionId : @"";
}

+ (NSString *)sessionToken
{
    User *user = [self fetchUser];
    if (!user) {
        return @"";
    }
    return user.sessionToken ? user.sessionToken :@"";
}

+ (NSString *)centerID
{
    UserInfo *userInfo = [self fetchUserInfo];
    if (!userInfo) {
        return @"";
    }
    return userInfo.centerId ? userInfo.centerId : @"";
}

+ (NSString *)userThumbnail
{
    UserInfo *userInfo = [self fetchUserInfo];
    if (!userInfo) {
        return @"";
    }
    return userInfo.headImageUrl ? userInfo.headImageUrl : @"";
}

+ (NSString *)phoneNumber
{
    UserInfo *userInfo = [self fetchUserInfo];
    if (!userInfo) {
        return @"";
    }
    return userInfo.mobilePhone ? userInfo.mobilePhone : @"";
}


@end
