//
//  NSString+Ret_msg.m
//  GlucoCare
//
//  Created by Dan on 15-1-12.
//  Copyright (c) 2015年 Tisson. All rights reserved.
//

#import "NSString+Ret_msg.h"
#import "AppDelegate+UserLogInOut.h"
#import <MBProgressHUD.h>

@implementation NSString (Ret_msg)

+ (NSString *)localizedMsgFromRet_code:(NSString *)ret_code withHUD:(BOOL)hasHud;
{
    NSString *path = [[NSBundle mainBundle] pathForResource:@"ret_code" ofType:@"plist"];
    NSDictionary *codeDic = [[NSDictionary alloc] initWithContentsOfFile:path];

    NSString *localizedString = [codeDic valueForKey:ret_code];
    
    if (!localizedString) {
        localizedString = NSLocalizedString(@"Request Error", nil);
    }
    
    
    if ([ret_code isEqualToString:@"-6"]) {
        
        if (!hasHud) {
            UIView *windowView = [UIApplication sharedApplication].keyWindow.viewForBaselineLayout;
            MBProgressHUD *hud = [[MBProgressHUD alloc] initWithView:windowView];
            [windowView addSubview:hud];
            hud.mode = MBProgressHUDModeText;
            hud.labelText = localizedString;
            [hud show:YES];
            [hud hide:YES afterDelay:1.25];
        }
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [AppDelegate userLogOut];
        });
        
    }
    
    
    return localizedString;
}


@end
