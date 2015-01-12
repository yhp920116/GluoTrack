//
//  NSString+Formatting.h
//  SugarNursing
//
//  Created by Dan on 15-1-11.
//  Copyright (c) 2015年 Tisson. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (Formatting)

+ (NSString *)formattingDateString:(NSString *)dateString From:(NSString *)format1 to:(NSString *)format2;

@end
