//
//  UserSetting.h
//  SugarNursing
//
//  Created by Dan on 15-1-3.
//  Copyright (c) 2015年 Tisson. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class UserID;

@interface UserSetting : NSManagedObject

@property (nonatomic, retain) NSString * fontSize;
@property (nonatomic, retain) NSString * unit;
@property (nonatomic, retain) UserID *userid;

@end
