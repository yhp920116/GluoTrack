//
//  FeedBackViewController.m
//  SugarNursing
//
//  Created by Dan on 14-11-27.
//  Copyright (c) 2014年 Tisson. All rights reserved.
//

#import "FeedBackViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "MyTextView.h"
#import "UtilsMacro.h"


@interface FeedBackViewController (){
    MBProgressHUD *hud;
}

@property (weak, nonatomic) IBOutlet MyTextView *textView;


@end

@implementation FeedBackViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"FeedBack", nil);
    [self configureTextView];
}

- (void)configureTextView
{
    self.textView.placeholder = @"请输入您的反馈";
    self.textView.placeholderColor = [UIColor lightGrayColor];
    [[self.textView layer] setBorderColor:[[[UIColor lightGrayColor] colorWithAlphaComponent:0.5] CGColor]];
    [[self.textView layer] setBorderWidth:1.0];
}

- (IBAction)feedBack:(id)sender
{
    [self sendFeedBack];
}

- (void)sendFeedBack
{
    
    hud = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
    [self.navigationController.view addSubview:hud];
    hud.mode = MBProgressHUDModeText;
    
    if (![ParseData parseStringIsAvaliable:self.textView.text]) {
        hud.labelText = NSLocalizedString(@"Format is not avaliable", nil);
        [hud show:YES];
        [hud hide:YES afterDelay:HUD_TIME_DELAY];
        return;
    }
    
    NSDictionary *parameters = @{@"method":@"sendfeedBack",
                                 @"sign":@"sign",
                                 @"sessionId":[NSString sessionID],
                                 @"content":self.textView.text,
                                 @"sendUser":[NSString userID]};
    
    [GCRequest userSendFeedbackWithParameters:parameters withBlock:^(NSDictionary *responseData, NSError *error) {
        
        if (!error) {
            if ([[responseData valueForKey:@"ret_code"] isEqualToString:@"0"]) {
                
                hud.labelText = NSLocalizedString(@"Send Message Succeed", nil);
            
            }else{
                
                hud.labelText = [responseData valueForKey:@"ret_msg"];
            }
        }else{
            hud.labelText = [error localizedDescription];
        }
        [hud show:YES];
        [hud hide:YES afterDelay:HUD_TIME_DELAY];
        
    }];
}

@end
