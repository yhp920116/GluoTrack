//
//  Advise.h
//  SugarNursing
//
//  Created by Dan on 15-1-9.
//  Copyright (c) 2015年 Tisson. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class UserID;

@interface Advise : NSManagedObject

@property (nonatomic, retain) NSString * content;
@property (nonatomic, retain) NSString * adviceId;
@property (nonatomic, retain) NSString * adviceTime;
@property (nonatomic, retain) NSString * exptId;
@property (nonatomic, retain) UserID *userid;

@end
