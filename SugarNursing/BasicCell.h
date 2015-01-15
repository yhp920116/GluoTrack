//
//  BasicCell.h
//  SugarNursing
//
//  Created by Dan on 14-12-2.
//  Copyright (c) 2014年 Tisson. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CustomLabel.h"

@interface BasicCell : UITableViewCell

@property (weak, nonatomic) IBOutlet CustomLabel *title;
@property (weak, nonatomic) IBOutlet UITextField *detailText;


@end
