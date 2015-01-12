//
//  ResetPwdViewController.m
//  SugarNursing
//
//  Created by Dan on 14-11-17.
//  Copyright (c) 2014年 Tisson. All rights reserved.
//

#import "ResetPwdViewController.h"
#import "AppDelegate+UserLogInOut.h"
#import "UtilsMacro.h"

@interface ResetPwdViewController (){
    MBProgressHUD *hud;
}

@property (weak, nonatomic) IBOutlet UITextField *codeField;
@property (weak, nonatomic) IBOutlet UITextField *passwordField;

@end

@implementation ResetPwdViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = NSLocalizedString(@"Reset", nil);
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.view endEditing:YES];
}

- (IBAction)getCodeAgain:(id)sender
{
    NSString *confirmInfo = [NSString stringWithFormat:@"%@:%@ %@",NSLocalizedString(@"willsendthecodeto", nil),self.areaCode, self.phoneNumber];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"surephonenumber", nil) message:confirmInfo delegate:self cancelButtonTitle:NSLocalizedString(@"cancel", nil) otherButtonTitles:NSLocalizedString(@"sure", nil), nil];
    [alert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (1 == buttonIndex) {
        
        hud = [[MBProgressHUD alloc] initWithView:self.view];
        [self.view addSubview:hud];
        
        hud.labelText = NSLocalizedString(@"Sending code", nil);
        [hud show:YES];
        
        NSDictionary *parameters = @{@"method":@"getCaptcha",
                                     @"mobile":self.phoneNumber,
                                     @"zone":self.areaCode};
        
        [GCRequest userGetCodeWithParameters:parameters withBlock:^(NSDictionary *responseData, NSError *error) {
            
            if (!error && [[responseData valueForKey:@"ret_code"] isEqualToString:@"-100"]) {
                hud.mode = MBProgressHUDModeText;
                hud.labelText = NSLocalizedString(@"Sending code succeed", nil);
                [hud hide:YES afterDelay:HUD_TIME_DELAY];
            }
            else{
                [hud hide:YES];
                //获取验证码失败
                NSString* str=[NSString stringWithFormat:NSLocalizedString(@"codesenderrormsg", nil)];
                UIAlertView* alert=[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"codesenderrtitle", nil) message:str delegate:self cancelButtonTitle:NSLocalizedString(@"sure", nil) otherButtonTitles:nil, nil];
                [alert show];
            }
        }];
    }
}

- (IBAction)resetAndLogin:(id)sender
{
    hud = [[MBProgressHUD alloc] initWithView:self.view];
    [self.view addSubview:hud];
    
    hud.labelText = @"Resetting...";
    [hud show:YES];
    
    NSDictionary *parameters = @{@"method":@"reSetPassword",
                                 @"mobile":self.phoneNumber,
                                 @"zone":self.areaCode,
                                 @"captcha":self.codeField.text,
                                 @"appType":@"1",
                                 @"password":self.passwordField.text};
    
    NSURLSessionDataTask *resetTask = [GCRequest userResetPasswordWithParameters:parameters withBlock:^(NSDictionary *responseData, NSError *error) {
        if (!error) {
            if ([[responseData objectForKey:@"ret_code"] isEqualToString:@"0"]) {
                hud.labelText = NSLocalizedString(@"Reset succeed", nil);
                [hud hide:YES afterDelay:HUD_TIME_DELAY];
                [AppDelegate userLogOut];
            }else{
                hud.mode = MBProgressHUDModeText;
                hud.labelText = [responseData objectForKey:@"ret_msg"];
                [hud hide:YES afterDelay:HUD_TIME_DELAY];
            }
        }else [hud hide:YES];
    }];
    [UIAlertView showAlertViewForTaskWithErrorOnCompletion:resetTask delegate:nil];
}
@end
