//
//  NSString+UserInfoCommon.m
//  SugarNursing
//
//  Created by Dan on 15-1-9.
//  Copyright (c) 2015年 Tisson. All rights reserved.
//

#import "NSString+UserInfoCommon.h"
#import "UtilsMacro.h"

@implementation NSString (UserInfoCommon)

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

@end
