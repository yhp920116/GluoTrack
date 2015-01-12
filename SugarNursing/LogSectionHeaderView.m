//
//  LogSectionHeaderView.m
//  SugarNursing
//
//  Created by Dan on 14-12-2.
//  Copyright (c) 2014年 Tisson. All rights reserved.
//

#import "LogSectionHeaderView.h"

@implementation LogSectionHeaderView


- (IBAction)toggleAdd:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(LogSectionHeaderView:sectionToggleAdd:)]) {
        [self.delegate LogSectionHeaderView:self sectionToggleAdd:self.section];
    }
}

@end
