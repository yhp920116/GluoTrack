//
//  DrugLog.h
//  GlucoTrack
//
//  Created by Dan on 15-2-2.
//  Copyright (c) 2015年 Tisson. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Medicine, RecordLog;

@interface DrugLog : NSManagedObject

@property (nonatomic, retain) NSString * medicineId;
@property (nonatomic, retain) NSString * medicinePeriod;
@property (nonatomic, retain) NSDate * medicineTime;
@property (nonatomic, retain) NSDate * updateTime;
@property (nonatomic, retain) NSOrderedSet *medicineList;
@property (nonatomic, retain) RecordLog *recordLog;
@end

@interface DrugLog (CoreDataGeneratedAccessors)

- (void)insertObject:(Medicine *)value inMedicineListAtIndex:(NSUInteger)idx;
- (void)removeObjectFromMedicineListAtIndex:(NSUInteger)idx;
- (void)insertMedicineList:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeMedicineListAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInMedicineListAtIndex:(NSUInteger)idx withObject:(Medicine *)value;
- (void)replaceMedicineListAtIndexes:(NSIndexSet *)indexes withMedicineList:(NSArray *)values;
- (void)addMedicineListObject:(Medicine *)value;
- (void)removeMedicineListObject:(Medicine *)value;
- (void)addMedicineList:(NSOrderedSet *)values;
- (void)removeMedicineList:(NSOrderedSet *)values;
@end
