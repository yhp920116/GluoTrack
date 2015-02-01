//
//  AboutUsViewController.m
//  SugarNursing
//
//  Created by Dan on 15-1-9.
//  Copyright (c) 2015年 Tisson. All rights reserved.
//

#import "AboutUsViewController.h"
#import <MobClick.h>
#import <MBProgressHUD.h>

@interface AboutUsViewController ()<UIAlertViewDelegate>
@property (weak, nonatomic) IBOutlet UILabel *versionLabel;
@property (strong, nonatomic ) NSString *appURL;

@end

@implementation AboutUsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title =  NSLocalizedString(@"About Us", nil);
    NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    self.versionLabel.text = [NSString stringWithFormat:@"%@: %@",NSLocalizedString(@"Version", nil),version];
}

- (IBAction)versionUpdate:(id)sender
{
    [MobClick checkUpdateWithDelegate:self selector:@selector(versionInfoCallBack:)];
    
}

- (void)versionInfoCallBack:(NSDictionary *)versionInfo
{
    
    if ([[versionInfo valueForKey:@"update"] isEqualToString:@"YES"]) {
        
        NSString *title = [NSString stringWithFormat:@"%@ %@",NSLocalizedString(@"New Version", nil),[versionInfo valueForKey:@"version"]];
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title message:[versionInfo valueForKey:@"update_log"] delegate:self cancelButtonTitle:NSLocalizedString(@"Skip", nil) otherButtonTitles:NSLocalizedString(@"Go", nil), nil];
        [alertView show];
        self.appURL = [versionInfo valueForKey:@"path"];
        
    }else{
        UIView *windowView = [UIApplication sharedApplication].keyWindow.viewForBaselineLayout;
        MBProgressHUD *hud = [[MBProgressHUD alloc] initWithView:windowView];
        [windowView addSubview:hud];
        hud.mode = MBProgressHUDModeText;
        hud.labelText = NSLocalizedString(@"已是最新版本", nil);
        [hud show:YES];
        [hud hide:YES afterDelay:1.25];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:self.appURL]];
    }
}

@end
