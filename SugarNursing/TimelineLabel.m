//
//  TimelineLabel.m
//  SugarNursing
//
//  Created by Dan on 14-11-18.
//  Copyright (c) 2014年 Tisson. All rights reserved.
//

#import "TimelineLabel.h"

@implementation TimelineLabel

- (void)layoutSubviews
{
    if (self.numberOfLines == 0) {
        if (self.preferredMaxLayoutWidth != self.frame.size.width) {
            self.preferredMaxLayoutWidth = self.frame.size.width;
            [self setNeedsUpdateConstraints];
        }
    }
}

- (CGSize)intrinsicContentSize
{
    CGSize size = [super intrinsicContentSize];
    if (self.numberOfLines == 0) {
        size.height += 1;
    }
    return size;
}

@end
