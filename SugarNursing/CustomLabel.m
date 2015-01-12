//
//  CustomLabel.m
//  SugarNursing
//
//  Created by Dan on 14-12-5.
//  Copyright (c) 2014年 Tisson. All rights reserved.
//

#import "CustomLabel.h"

@implementation CustomLabel

- (void)customSetup
{
    self.font = [UIFont systemFontOfSize:14.0f];
}

- (id)initWithFrame:(CGRect)frame
{
    if (!(self = [super initWithFrame:frame])) return nil;
    
    [self customSetup];
    return self;
}

- (void)awakeFromNib
{
    [self customSetup];
}

@end
