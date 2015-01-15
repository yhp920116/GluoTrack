//
//  DetectCell.h
//  GlucoCare
//
//  Created by Dan on 15-1-14.
//  Copyright (c) 2015年 Tisson. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CustomLabel.h"

@interface DetectCell : UITableViewCell
@property (weak, nonatomic) IBOutlet CustomLabel *detectType;
@property (weak, nonatomic) IBOutlet CustomLabel *detectValue;
@property (weak, nonatomic) IBOutlet CustomLabel *detectUnit;

@end
