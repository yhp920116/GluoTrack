//
//  LoginViewController.m
//  SugarNursing
//
//  Created by Dan on 14-11-6.
//  Copyright (c) 2014年 Tisson. All rights reserved.
//

#import "LoginViewController.h"
#import "AppDelegate+UserLogInOut.h"
#import "UIViewController+Notifications.h"
#import "VerificationViewController.h"
#import "UtilsMacro.h"


@interface LoginViewController (){
    MBProgressHUD *hud;
}

@property (weak, nonatomic) IBOutlet UITextField *usernameField;
@property (weak, nonatomic) IBOutlet UITextField *passwordField;


@end

@implementation LoginViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

#pragma mark - PrepareForSegue

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    VerificationViewController *verificationVC= (VerificationViewController *)[[[segue destinationViewController] viewControllers] objectAtIndex:0];
    
    if ([segue.identifier isEqualToString:@"Regist"])
    {
        verificationVC.title = NSLocalizedString(@"Register", nil);
        verificationVC.verifiedType = 0;

    }
    else if ([segue.identifier isEqualToString:@"Reset"])
    {
        verificationVC.title = NSLocalizedString(@"Reset", nil);
        verificationVC.verifiedType = 1;

    }
    
}

#pragma mark - KeyboardNotification

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self registerForKeyboardNotification:@selector(keyboardWillShow:) :@selector(keyboardWillHide:)];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self removeKeyboardNotification];
}

- (void)keyboardWillShow:(NSNotification *)aNotification
{
    NSDictionary *info = [aNotification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    CGFloat kbHeight = kbSize.height;
    CGFloat screenHeight = [[UIScreen mainScreen] bounds].size.height;
    
    CGFloat calHeight;
    if (screenHeight - kbHeight - 200 >= 20) {
         calHeight = screenHeight/2-100;

    } else {
        return;
    }
    
    if (kbHeight > calHeight) {
        self.loginViewYCons.constant = -(kbHeight-calHeight);
        [self.view setNeedsUpdateConstraints];
        
        [UIView animateWithDuration:0.4 animations:^{
            [self.view layoutIfNeeded];
        }];
    }
}

- (void)keyboardWillHide:(NSNotification *)aNotification
{
    self.loginViewYCons.constant  = 0;
    [UIView animateWithDuration:0.4 animations:^{
        [self.view layoutIfNeeded];
    }];
}

#pragma mark - userAction

- (IBAction)userRegist:(id)sender
{
    
}

- (IBAction)userLogin:(id)sender
{
//    if (![ParseData parsePasswordIsAvaliable:self.passwordField.text]) {
//        
//        [[[UIAlertView alloc] initWithTitle:nil message:NSLocalizedString(@"密码要大于6位数", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"cancel", nil) otherButtonTitles:NSLocalizedString(@"sure", nil), nil] show];
//        
//    }else{
//        
//        [self login];
//    }
    [self login];
}

- (void)login
{
    hud = [[MBProgressHUD alloc] initWithView:self.view];
    [self.view addSubview:hud];
    hud.labelText = NSLocalizedString(@"Login..", nil);
    [hud show:YES];
    
    NSDictionary *parameters = @{@"method":@"verify",
                                 @"accountName":self.usernameField.text,
                                 @"password":self.passwordField.text};
    
    NSURLSessionDataTask *loginTask = [GCRequest userLoginWithParameters:parameters withBlock:^(NSDictionary *responseData, NSError *error) {
        
        if (!error) {
            if ([[responseData objectForKey:@"ret_code"] isEqualToString:@"0"]) {
                
                // 这里对获取到的会话标识、会话标识Token和用户标识等进行数据持久化
                
                NSMutableDictionary *responseDic = [responseData mutableCopy];
                [responseDic setValue:[self.passwordField.text md5] forKey:@"passWord"];
                [responseDic setValue:self.usernameField.text forKey:@"userName"];
                
                NSArray *userObjects = [User findAllInContext:[CoreDataStack sharedCoreDataStack].context];
                
                // 这里的user是一个单例，有且只有一个用户数据，标识当前的用户
                User *user;
                
                if ([userObjects count]== 0) {
                    user = [User createEntityInContext:[CoreDataStack sharedCoreDataStack].context];
                    
                }else{
                    user = userObjects[0];
                }
                
                [user updateCoreDataForData:responseDic withKeyPath:nil];
                [[CoreDataStack sharedCoreDataStack] saveContext];
                
                DDLogInfo(@"Saving user: %@",user);
                
                [AppDelegate userLogIn];
                [hud hide:YES];
                
            }else{
                hud.mode = MBProgressHUDModeText;
                hud.labelText = [responseData objectForKey:@"ret_msg"];
                [hud hide:YES afterDelay:HUD_TIME_DELAY];
            }
            
        }else{
            [hud hide:YES];
        }
        
    }];
    [UIAlertView showAlertViewForTaskWithErrorOnCompletion:loginTask delegate:nil];
}

#pragma mark - textfieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    switch (textField.tag) {
        case 11:
            self.userFieldBG.image = [UIImage imageNamed:@"003"];
            break;
        case 12:
            self.pwdFieldBG.image = [UIImage imageNamed:@"003"];
            break;
    }
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    switch (textField.tag) {
        case 11:
            self.userFieldBG.image = [UIImage imageNamed:@"004"];
            break;
        case 12:
            self.pwdFieldBG.image = [UIImage imageNamed:@"004"];
            break;
    }
}

#pragma mark - dismissKeyboard

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField
{
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    [self userLogin:nil];
    return YES;
}

#pragma mark - unwindSegue

- (IBAction)back:(UIStoryboardSegue *)unwindSegue
{
//    UIViewController *sourceViewController = unwindSegue.sourceViewController;
}


@end
