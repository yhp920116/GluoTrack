//
//  RecordLogList.h
//  SugarNursing
//
//  Created by Dan on 15-1-11.
//  Copyright (c) 2015年 Tisson. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class RecordLog;

@interface RecordLogList : NSManagedObject

@property (nonatomic, retain) NSString * eventObject;
@property (nonatomic, retain) NSString * eventValue;
@property (nonatomic, retain) NSString * eventAmount;
@property (nonatomic, retain) NSString * eventId;
@property (nonatomic, retain) NSString * eventMode;
@property (nonatomic, retain) NSString * eventUnit;
@property (nonatomic, retain) RecordLog *recordLog;

@end
