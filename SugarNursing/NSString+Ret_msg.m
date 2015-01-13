//
//  NSString+Ret_msg.m
//  GlucoCare
//
//  Created by Dan on 15-1-12.
//  Copyright (c) 2015年 Tisson. All rights reserved.
//

#import "NSString+Ret_msg.h"

@implementation NSString (Ret_msg)

+ (NSString *)localizedMsgFromRet_code:(NSString *)ret_code
{
    NSString *path = [[NSBundle mainBundle] pathForResource:@"ret_code" ofType:@"plist"];
    NSDictionary *codeDic = [[NSDictionary alloc] initWithContentsOfFile:path];

    NSString *localizedString = [codeDic valueForKey:ret_code];
    
    if (!localizedString) {
        localizedString = NSLocalizedString(@"Request Error", nil);
    }
    
    return localizedString;
}


@end
