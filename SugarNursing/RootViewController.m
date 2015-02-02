//
//  RootViewController.m
//  SugarNursing
//
//  Created by Dan on 14-11-5.
//  Copyright (c) 2014年 Tisson. All rights reserved.
//

#import "RootViewController.h"
#import "UIStoryboard+Storyboards.h"
#import "TestTrackerViewController.h"
#import "UtilsMacro.h"

@interface RootViewController ()

@end

@implementation RootViewController

- (void)awakeFromNib
{
    self.menuPreferredStatusBarStyle = UIStatusBarStyleLightContent;
    self.contentViewShadowColor = [UIColor blackColor];
    self.contentViewShadowOffset = CGSizeMake(0, 0);
    self.contentViewShadowOpacity = 0.6;
    self.contentViewShadowRadius = 4;
    self.contentViewShadowEnabled = YES;
    
    self.contentViewController = [[UIStoryboard testTracker] instantiateInitialViewController];
    self.leftMenuViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"LeftMenu"];
//    self.rightMenuViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"RightMenu"];
    self.delegate = self;
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self getNewMessages];
    [self performSelector:@selector(showMenu:) withObject:nil afterDelay:1.25];
}

//- (void)configureNewMessages
//{
//    [NSTimer scheduledTimerWithTimeInterval:60*30 target:self selector:@selector(getNewMessages) userInfo:nil repeats:YES];
//}

- (void)getNewMessages
{
    NSDictionary *parameters = @{@"method":@"getNewMessageCount",
                                 @"recvUser":[NSString linkmanID],
                                 @"sessionId":[NSString sessionID],
                                 @"sign":@"sign"};
    
    [GCRequest userGetNewMessagesWithParameters:parameters withBlock:^(NSDictionary *responseData, NSError *error) {
        if (!error) {
            NSString *ret_code = [responseData valueForKey:@"ret_code"];
            if ([ret_code isEqualToString:@"0"]) {
                NSString *newMessages = [NSString stringWithFormat:@"%@",[responseData valueForKey:@"countListSize"]];
                [UIApplication sharedApplication].applicationIconBadgeNumber = newMessages.integerValue;
            }
        }
    }];
}

- (void)showMenu:(id)sender
{
    [self presentLeftMenuViewController];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
