//
//  WarningViewController.h
//  SugarNursing
//
//  Created by Dan on 14-11-23.
//  Copyright (c) 2014年 Tisson. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SwipeView.h"

@interface RemindViewController : UIViewController<UITableViewDataSource, UITableViewDelegate, SwipeViewDataSource, SwipeViewDelegate, UITabBarDelegate>

@property (strong, nonatomic) NSMutableArray *dataArray;

@property (weak, nonatomic) IBOutlet SwipeView *swipeView;
@property (weak, nonatomic) IBOutlet UITabBar *tabBar;

@end
