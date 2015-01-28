//
//  RebindMobileViewController.m
//  SugarNursing
//
//  Created by Dan on 14-12-18.
//  Copyright (c) 2014年 Tisson. All rights reserved.
//

#import "RebindMobileViewController.h"
#import "UIStoryboard+Storyboards.h"
#import "UtilsMacro.h"

@interface RebindMobileViewController ()<UITextFieldDelegate>{
    MBProgressHUD *hud;
}

@property (weak, nonatomic) IBOutlet UIImageView *mobileFieldBG;
@property (weak, nonatomic) IBOutlet UIImageView *passwordFieldBG;
@property (weak, nonatomic) IBOutlet UITextField *mobileField;
@property (weak, nonatomic) IBOutlet UITextField *passwordField;
@property (weak, nonatomic) IBOutlet UIButton *verifiedBtn;


@end

@implementation RebindMobileViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = NSLocalizedString(@"Verify your account", nil);
}

- (IBAction)verified:(id)sender
{
    if (![ParseData parsePasswordIsAvaliable:self.passwordField.text]) {
        return;
    }
    
    hud = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
    [self.navigationController.view addSubview:hud];
    hud.labelText = NSLocalizedString(@"Verifying...",nil);
    [hud show:YES];
    
    NSDictionary *parameters = @{@"method":@"verify",
                                 @"accountName":self.mobileField.text,
                                 @"password":self.passwordField.text};
    NSURLSessionDataTask *verifyTask = [GCRequest userLoginWithParameters:parameters withBlock:^(NSDictionary *responseData, NSError *error) {
        if (!error) {
            NSString *ret_code = [responseData objectForKey:@"ret_code"];
            if ([ret_code isEqualToString:@"0"]) {
                // 重新验证成功后，更新账户信息
                NSMutableDictionary *responseDic = [responseData mutableCopy];
                [responseDic setValue:[self.passwordField.text md5] forKey:@"passWord"];
                [responseDic setValue:self.mobileField.text forKey:@"userName"];
                
                User *user;
                
                NSArray *userObjects = [User findAllInContext:[CoreDataStack sharedCoreDataStack].context];
                if (userObjects.count == 0) {
                    user = [User createEntityInContext:[CoreDataStack sharedCoreDataStack].context];
                }else{
                    user = userObjects[0];
                }
                [user updateCoreDataForData:responseDic withKeyPath:nil];
                [[CoreDataStack sharedCoreDataStack] saveContext];
                
                [self performSegueWithIdentifier:@"ToRebind" sender:nil];
                [hud hide:YES];
            }else{
                hud.labelText = [NSString localizedMsgFromRet_code:ret_code withHUD:YES];
            }
        }else{
            hud.labelText = [error localizedDescription];
        }
        
        [hud hide:YES afterDelay:HUD_TIME_DELAY];
    }];
    [UIAlertView showAlertViewForTaskWithErrorOnCompletion:verifyTask delegate:nil];
}

#pragma mark - TextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    if ([textField isEqual:self.mobileField]) {
        self.mobileFieldBG.image = [UIImage imageNamed:@"007-2"];
    }
    if ([textField isEqual:self.passwordField]) {
        self.passwordFieldBG.image = [UIImage imageNamed:@"007-2"];
    }
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    if ([textField isEqual:self.mobileField]) {
        self.mobileFieldBG.image = [UIImage imageNamed:@"007"];
    }
    if ([textField isEqual:self.passwordField]) {
        self.passwordFieldBG.image = [UIImage imageNamed:@"007"];
    }
}



@end
