//
//  UserID.h
//  SugarNursing
//
//  Created by Dan on 15-1-5.
//  Copyright (c) 2015年 Tisson. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Advise, MedicalRecord, Message, RecordLog, UserInfo, UserSetting;

@interface UserID : NSManagedObject

@property (nonatomic, retain) NSString * linkManId;
@property (nonatomic, retain) NSString * userId;
@property (nonatomic, retain) Advise *advise;
@property (nonatomic, retain) MedicalRecord *medicalRecord;
@property (nonatomic, retain) Message *message;
@property (nonatomic, retain) UserInfo *userInfo;
@property (nonatomic, retain) UserSetting *userSetting;
@property (nonatomic, retain) RecordLog *recordLog;

@end
