//
//  NSString+Formatting.m
//  SugarNursing
//
//  Created by Dan on 15-1-11.
//  Copyright (c) 2015年 Tisson. All rights reserved.
//

#import "NSString+Formatting.h"

@implementation NSString (Formatting)

+ (NSString *)formattingDateString:(NSString *)dateString From:(NSString *)format1 to:(NSString *)format2
{
    if (!dateString || !format1 || !format2) {
        return nil;
    }
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:format1];
    
    NSDate *date = [dateFormatter dateFromString:dateString];

    [dateFormatter setDateFormat:format2];
    
    return [dateFormatter stringFromDate:date];
    
}

@end
