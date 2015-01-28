//
//  RegistViewController.m
//  SugarNursing
//
//  Created by Dan on 14-11-16.
//  Copyright (c) 2014年 Tisson. All rights reserved.
//

#import "RegistViewController.h"
#import "AppDelegate+UserLogInOut.h"
#import "UtilsMacro.h"

@interface RegistViewController ()<UIAlertViewDelegate,UIActionSheetDelegate>{
    MBProgressHUD *hud;
}


@end


@implementation RegistViewController

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.view endEditing:YES];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"Register", nil);
    if ([self respondsToSelector:@selector(automaticallyAdjustsScrollViewInsets)]) {
        self.automaticallyAdjustsScrollViewInsets = NO;
    }
}

#pragma mark - IBAction

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
            NSString *ret_code = [responseData objectForKey:@"ret_code"];
            if (!error && [ret_code isEqualToString:@"0"]) {
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



- (IBAction)genderPicker:(id)sender
{
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"choosegender", nil) delegate:self cancelButtonTitle:nil destructiveButtonTitle:NSLocalizedString(@"cancel", nil) otherButtonTitles:NSLocalizedString(@"male", nil),NSLocalizedString(@"female", nil), nil];
    [sheet showInView:self.view];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != 0) {
        [self.genderBtn setTitle:[actionSheet buttonTitleAtIndex:buttonIndex] forState:UIControlStateNormal];
    }
}


- (IBAction)datePicker:(id)sender
{
    [self.view endEditing:YES];
    
    hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.customView = self.pickerView;
    hud.margin = 0;
    hud.mode = MBProgressHUDModeCustomView;
    [hud show:YES];
}

- (IBAction)dateCancelAndConfirm:(id)sender
{
    UIButton *btn = (UIButton *)sender;

    if (btn.tag == 1001) {
        if ([ParseData parseDateIsAvaliable:self.datePicker.date]) {
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateFormat:@"YYYY-MM-dd"];
            NSString *dateString = [dateFormatter stringFromDate:self.datePicker.date];
            [self.dateBtn setTitle:dateString forState:UIControlStateNormal];
        }else [hud hide:YES];
    }
    [hud hide:YES];
}

- (IBAction)regist:(id)sender
{
    if ([ParseData parsePasswordIsAvaliable:self.passwordField.text]) {
        [self userRegister];
    }
}

- (void)userRegister
{
    hud = [[MBProgressHUD alloc] initWithView:self.view];
    [self.view addSubview:hud];
    
    hud.labelText = NSLocalizedString(@"Registering...", nil);
    [hud show:YES];
    
    NSDictionary *parameters = @{@"method":@"accountRegist",
                                 @"mobile":self.phoneNumber,
                                 @"captcha":self.codeField.text,
                                 @"password":self.passwordField.text,
                                 @"userName":self.usernameField.text,
                                 @"sex":[self.genderBtn currentTitle],
                                 @"birthday":[self.dateBtn currentTitle],
                                 @"zone":self.areaCode,
                                 };
    
    NSURLSessionDataTask *registerTask = [GCRequest userRegisterWithParameters:parameters withBlock:^(NSDictionary *responseData, NSError *error) {
        
        if (!error) {
            NSString *ret_code = [responseData objectForKey:@"ret_code"];
            if ([ret_code isEqualToString:@"0"]){
                hud.mode = MBProgressHUDModeText;
                hud.labelText = NSLocalizedString(@"Register succeed", nil);
                [hud hide:YES afterDelay:HUD_TIME_DELAY];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [AppDelegate userLogOut];
                });
                
            }else{
                hud.mode = MBProgressHUDModeText;
                hud.labelText = [NSString localizedMsgFromRet_code:ret_code withHUD:YES];
                [hud hide:YES afterDelay:HUD_TIME_DELAY];
            }
            
        }else [hud hide:YES];
        
    }];
    [UIAlertView showAlertViewForTaskWithErrorOnCompletion:registerTask delegate:nil];
}

@end
