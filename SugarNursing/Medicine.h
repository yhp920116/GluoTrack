//
//  Medicine.h
//  GlucoTrack
//
//  Created by Dan on 15-1-19.
//  Copyright (c) 2015年 Tisson. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class DrugLog;

@interface Medicine : NSManagedObject

@property (nonatomic, retain) NSString * dose;
@property (nonatomic, retain) NSString * drug;
@property (nonatomic, retain) NSString * sort;
@property (nonatomic, retain) NSString * unit;
@property (nonatomic, retain) NSString * usage;
@property (nonatomic, retain) DrugLog *drugLog;

@end
