//
//  YALSunyRefreshControl.h
//  YALSunyPullToRefresh
//
//  Created by Konstantin Safronov on 12/24/14.
//  Copyright (c) 2014 Konstantin Safronov. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol YALSunnyRefreshControlDelegate;

@interface YALSunnyRefreshControl : UIView

@property (nonatomic, assign) id<YALSunnyRefreshControlDelegate>delegate;

+ (YALSunnyRefreshControl*)attachToScrollView:(UIScrollView *)scrollView;

- (void)startRefreshing;

- (void)endRefreshing;

@end

@protocol YALSunnyRefreshControlDelegate <NSObject>

@required

- (void)YALRefreshViewDidStartLoading:(YALSunnyRefreshControl *)view;

@end
