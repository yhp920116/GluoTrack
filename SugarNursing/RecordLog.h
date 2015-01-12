//
//  RecordLog.h
//  SugarNursing
//
//  Created by Dan on 15-1-8.
//  Copyright (c) 2015年 Tisson. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class RecordLogList, UserID;

@interface RecordLog : NSManagedObject

@property (nonatomic, retain) NSString * id;
@property (nonatomic, retain) NSString * logType;
@property (nonatomic, retain) NSString * time;
@property (nonatomic, retain) NSOrderedSet *eventList;
@property (nonatomic, retain) UserID *userid;
@end

@interface RecordLog (CoreDataGeneratedAccessors)

- (void)insertObject:(RecordLogList *)value inEventListAtIndex:(NSUInteger)idx;
- (void)removeObjectFromEventListAtIndex:(NSUInteger)idx;
- (void)insertEventList:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeEventListAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInEventListAtIndex:(NSUInteger)idx withObject:(RecordLogList *)value;
- (void)replaceEventListAtIndexes:(NSIndexSet *)indexes withEventList:(NSArray *)values;
- (void)addEventListObject:(RecordLogList *)value;
- (void)removeEventListObject:(RecordLogList *)value;
- (void)addEventList:(NSOrderedSet *)values;
- (void)removeEventList:(NSOrderedSet *)values;
@end
