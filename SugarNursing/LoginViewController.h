//
//  LoginViewController.h
//  SugarNursing
//
//  Created by Dan on 14-11-6.
//  Copyright (c) 2014年 Tisson. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LoginViewController : UIViewController


@property (weak, nonatomic) IBOutlet UIImageView *userFieldBG;
@property (weak, nonatomic) IBOutlet UIImageView *pwdFieldBG;


@property (weak, nonatomic) IBOutlet NSLayoutConstraint *loginViewYCons;


- (IBAction)userRegist:(id)sender;
- (IBAction)userLogin:(id)sender;


@end
