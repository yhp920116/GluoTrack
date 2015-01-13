//
//  VerificationViewController.m
//  SugarNursing
//
//  Created by Dan on 14-12-16.
//  Copyright (c) 2014年 Tisson. All rights reserved.
//

#import "VerificationViewController.h"
#import "AreaNameAndCodeViewController.h"
#import "RegistViewController.h"
#import "ResetPwdViewController.h"
#import "UtilsMacro.h"



@interface VerificationViewController ()<UIAlertViewDelegate>{
    MBProgressHUD *hud;
}

@property (strong, nonatomic) CountryAndAreaCode *countryAndAreaCode;

@end

@implementation VerificationViewController

- (void)awakeFromNib
{
    // Default CountryAndAreaCode
    self.countryAndAreaCode = [[CountryAndAreaCode alloc] init];
    self.countryAndAreaCode.countryName = NSLocalizedString(@"hongkong", nil);
    self.countryAndAreaCode.areaCode = @"852";
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self updateLabels];

}

- (void)viewDidLoad {
    [super viewDidLoad];

}

- (void)updateLabels
{
    self.countryLabel.text = self.countryAndAreaCode.countryName;
    self.areaCodeLabel.text = [NSString stringWithFormat:@"+%@",self.countryAndAreaCode.areaCode];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat height = 0;
    switch (indexPath.row) {
        case 0:
        case 1:
        case 3:
            height = 30;
            break;
        case 2:
            height = 44;
            break;
        default:
            break;
    }
    return height;
}

- (IBAction)GetVerificationCode:(id)sender
{
    if (!(self.phoneField.text.length == 11 || self.phoneField.text.length == 8)) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"notice", nil) message:NSLocalizedString(@"errorphonenumber", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"sure", nil) otherButtonTitles:nil, nil];
        [alert show];
        return;
    }
    
    NSString *confirmInfo = [NSString stringWithFormat:@"%@:%@ %@",NSLocalizedString(@"willsendthecodeto", nil),self.countryAndAreaCode.areaCode, self.phoneField.text];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"surephonenumber", nil) message:confirmInfo delegate:self cancelButtonTitle:NSLocalizedString(@"cancel", nil) otherButtonTitles:NSLocalizedString(@"sure", nil), nil];
    [alert show];

}

- (void)userIsRegistered
{
    
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) {
        
        if (self.verifiedType == VerifiedTypeReset) {
            [self userGetCode];
            return;
        }
        
        hud = [[MBProgressHUD alloc] initWithView:self.view];
        [self.view addSubview:hud];
        
        hud.labelText = NSLocalizedString(@"Sending code", nil);
        [hud show:YES];
        
        NSDictionary *parameters = @{@"method":@"isMember",
                                     @"mobile":self.phoneField.text,
                                     @"memberType":@"2"};
        
        NSURLSessionDataTask *isRegisteredTask = [GCRequest userIsRegisteredWithParameters:parameters withBlock:^(NSDictionary *responseData, NSError *error) {
            if (!error) {
                NSString *ret_code = [responseData objectForKey:@"ret_code"];
                if ([ret_code isEqualToString:@"0"]) {
                    if ([[responseData valueForKey:@"isMember"] isEqualToString:@"0"]){
                        [self userGetCode];
                    }
                    
                }else{
                    hud.mode = MBProgressHUDModeText;
                    hud.labelText = [NSString localizedMsgFromRet_code:ret_code];
                    [hud hide:YES afterDelay:HUD_TIME_DELAY];
                }
            }else{
                [hud hide:YES];
            }
        }];
        
        [UIAlertView showAlertViewForTaskWithErrorOnCompletion:isRegisteredTask delegate:nil];
    }
}

- (void)userGetCode
{
    NSDictionary *parameters = @{@"method":@"getCaptcha",
                                 @"mobile":self.phoneField.text,
                                 @"zone":self.countryAndAreaCode.areaCode};
    
    [GCRequest userGetCodeWithParameters:parameters withBlock:^(NSDictionary *responseData, NSError *error) {
        
        hud.mode = MBProgressHUDModeText;
        
        if (!error) {
            
            NSString *ret_code = [responseData valueForKey:@"ret_code"];
            if ([ret_code isEqualToString:@"0"]) {
                
                [hud hide:YES afterDelay:HUD_TIME_DELAY];
                switch (self.verifiedType) {
                    case 0:
                        [self performSegueWithIdentifier:@"Register" sender:nil];
                        break;
                    case 1:
                        [self performSegueWithIdentifier:@"Reset" sender:nil];
                        break;
                }
            }
            else{
                hud.labelText = [NSString localizedMsgFromRet_code:ret_code];
            }
        }else{
            hud.labelText = [error localizedDescription];
        }
        
        [hud show:YES];
        [hud hide:YES afterDelay:HUD_TIME_DELAY];
        
    }];
    
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([segue.identifier isEqual:@"AreaCode"])
    {
        AreaNameAndCodeViewController *areaNameAndCodeVC = [segue destinationViewController];
        areaNameAndCodeVC.countryAndAreaCode = self.countryAndAreaCode;

    }else if ([segue.identifier isEqual:@"Register"])
    {
        RegistViewController *registerVC = [segue destinationViewController];
        registerVC.areaCode = self.countryAndAreaCode.areaCode;
        registerVC.phoneNumber = self.phoneField.text;
    }else if ([segue.identifier isEqual:@"Reset"])
    {
        ResetPwdViewController *resetVC = [segue destinationViewController];
        resetVC.areaCode = self.countryAndAreaCode.areaCode;
        resetVC.phoneNumber = self.phoneField.text;
    }
}

- (IBAction)back:(UIStoryboardSegue*)unwindSegue
{
    
}

@end
