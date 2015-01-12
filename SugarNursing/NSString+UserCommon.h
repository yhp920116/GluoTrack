//
//  NSString+UserCommon.h
//  SugarNursing
//
//  Created by Dan on 14-12-27.
//  Copyright (c) 2014年 Tisson. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (UserCommon)

+ (NSString *)userID;
+ (NSString *)linkmanID;
+ (NSString *)sessionID;
+ (NSString *)sessionToken;

@end
