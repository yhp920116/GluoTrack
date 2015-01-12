//
//  NSDictionary+Formatting.m
//  SugarNursing
//
//  Created by Dan on 14-12-30.
//  Copyright (c) 2014年 Tisson. All rights reserved.
//

#import "NSDictionary+Formatting.h"
#import "UtilsMacro.h"

@implementation NSDictionary (Formatting)


- (void)dateFormattingToUser:(NSString *)dateFormatting ForKey:(NSString *)key
{
    if (![[self allKeys] containsObject:key]) {
        return;
    }
    if (![self isKindOfClass:[NSMutableDictionary class]]) {
        DDLogInfo(@"Running %@, %@ is not Mutable!",NSStringFromSelector(_cmd),self);
        return;
    }
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyyMMddHHmmss"];
    NSDate *date = [dateFormatter dateFromString:[NSString stringWithFormat:@"%@",self[key]]];
    [dateFormatter setDateFormat:dateFormatting];
    
    [self setValue:[dateFormatter stringFromDate:date] forKey:key];
}

- (void)dateFormattingFromUser:(NSString *)userDateFormatting ToServer:(NSString *)serverDateFormatting ForKey:(NSString *)key
{
    if (![[self allKeys] containsObject:key]) {
        return;
    }
    if (![self isKindOfClass:[NSMutableDictionary class]]) {
        DDLogInfo(@"Running %@, %@ is not Mutable!",NSStringFromSelector(_cmd),self);
        return;
    }
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:userDateFormatting];
    NSDate *date = [dateFormatter dateFromString:self[key]];
    [dateFormatter setDateFormat:serverDateFormatting];
    
    [self setValue:[dateFormatter stringFromDate:date] forKey:key];
    
}

- (void)sexFormattingToUserForKey:(NSString *)key
{
    if (![[self allKeys] containsObject:key]) {
        return;
    }
    if (![self isKindOfClass:[NSMutableDictionary class]]) {
        DDLogInfo(@"Running %@, %@ is not Mutable!",NSStringFromSelector(_cmd),self);
        return;
    }
    
    NSString *sex = [NSString stringWithFormat:@"%@",self[key]];
    
    [self setValue:[sex isEqualToString:@"01"] ? NSLocalizedString(@"male", nil) :[sex isEqualToString:@"00"] ? NSLocalizedString(@"female", nil) : nil forKey:key];
}

- (void)sexFormattingToServerForKey:(NSString *)key
{
    if (![[self allKeys] containsObject:key]) {
        return;
    }
    if (![self isKindOfClass:[NSMutableDictionary class]]) {
        DDLogInfo(@"Running %@, %@ is not Mutable!",NSStringFromSelector(_cmd),self);
        return;
    }
    
    NSString *sex = [NSString stringWithFormat:@"%@",self[key]];
    
    [self setValue:[sex isEqualToString:NSLocalizedString(@"female", nil)] ? @"00" :[sex isEqualToString:NSLocalizedString(@"male", nil)] ? @"01" : nil forKey:key];
    
}

- (void)serverLevelFormattingToUserForKey:(NSString *)key
{
    if (![[self allKeys] containsObject:key]) {
        return;
    }
    if (![self isKindOfClass:[NSMutableDictionary class]]) {
        DDLogInfo(@"Running %@, %@ is not Mutable!",NSStringFromSelector(_cmd),self);
        return;
    }
    
    NSString *server = [NSString stringWithFormat:@"%@",self[key]];
    
    [self setValue:[server isEqualToString:@"00"] ? NSLocalizedString(@"No avaliable", nil) :[server isEqualToString:@"01"] ? NSLocalizedString(@"Avaliable", nil) : nil forKey:key];
    
}


@end
