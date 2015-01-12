//
//  ToRebindMobileViewController.m
//  SugarNursing
//
//  Created by Dan on 15-1-3.
//  Copyright (c) 2015年 Tisson. All rights reserved.
//

#import "ToRebindMobileViewController.h"
#import "UtilsMacro.h"

@interface ToRebindMobileViewController (){
    MBProgressHUD *hud;
}

@property (weak, nonatomic) IBOutlet UITextField *mobileField;


@end

@implementation ToRebindMobileViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = NSLocalizedString(@"Rebind Your Mobile", nil);

}

- (IBAction)rebind:(id)sender
{
    hud = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
    [self.navigationController.view addSubview:hud];
    hud.labelText = NSLocalizedString(@"Rebinding...", nil);
    [hud show:YES];
    
    NSDictionary *parameters = @{@"method":@"accountEdit",
                                 @"sign":@"sign",
                                 @"sessionId":[NSString sessionID],
                                 @"userId":[NSString userID],
                                 @"mobile":self.mobileField.text,
                                 };
    
    NSURLSessionDataTask *rebindTask = [GCRequest userRebindMobileWithParameters:parameters withBlock:^(NSDictionary *responseData, NSError *error) {
        
        if (!error) {
            NSString *ret_code = [responseData objectForKey:@"ret_code"];
            if ([ret_code isEqualToString:@"0"]) {
                hud.mode = MBProgressHUDModeText;
                hud.labelText = NSLocalizedString(@"Rebind succeed", nil);
                [hud hide:YES afterDelay:HUD_TIME_DELAY];
                [self.navigationController popToRootViewControllerAnimated:YES];
            }else{
                hud.mode = MBProgressHUDModeText;
                hud.labelText = [NSString localizedMsgFromRet_code:ret_code];
                [hud hide:YES afterDelay:HUD_TIME_DELAY];
            }
        }else{
            [hud hide:YES];
        }
        
    }];
    [UIAlertView showAlertViewForTaskWithErrorOnCompletion:rebindTask delegate:nil];
    
}


@end
