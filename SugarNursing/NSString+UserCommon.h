//
//  NSString+UserCommon.h
//  SugarNursing
//
//  Created by Dan on 14-12-27.
//  Copyright (c) 2014年 Tisson. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (UserCommon)

// User
+ (NSString *)userID;
+ (NSString *)linkmanID;
+ (NSString *)sessionID;
+ (NSString *)sessionToken;

// UserInfo
+ (NSString *)userName;
+ (NSString *)centerID;
+ (NSString *)userThumbnail;
+ (NSString *)phoneNumber;
+ (NSString *)indentityCard;
+ (NSString *)email;


@end
