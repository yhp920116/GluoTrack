//
//  SWTableViewCell+RigthButtons.m
//  SugarNursing
//
//  Created by Dan on 14-12-5.
//  Copyright (c) 2014年 Tisson. All rights reserved.
//

#import "SWTableViewCell+RigthButtons.h"

@implementation SWTableViewCell (RigthButtons)

- (void)addRightButtons
{
    self.rightUtilityButtons = [self rightButtons];
}

- (void)addLeftButtons
{
    self.leftUtilityButtons = [self leftButtons];
}

- (NSArray *)rightButtons
{
    NSMutableArray *rightUtilityButtons = [NSMutableArray new];
    [rightUtilityButtons sw_addUtilityButtonWithColor:
     [UIColor colorWithRed:1.0f green:0.231f blue:0.188 alpha:1.0f]
                                                title:@"Delete"];
    
    return rightUtilityButtons;
}

- (NSArray *)leftButtons
{
    NSMutableArray *leftUtilityButtons = [NSMutableArray new];
    [leftUtilityButtons sw_addUtilityButtonWithColor:
     [UIColor colorWithRed:0.78f green:0.78f blue:0.8f alpha:1.0]
                                                title:@"More"];
    return leftUtilityButtons;
}


@end
