//
//  MedicateCell.h
//  SugarNursing
//
//  Created by Dan on 14-12-2.
//  Copyright (c) 2014年 Tisson. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SWTableViewCell.h>

@interface MedicateCell : SWTableViewCell

@property (weak, nonatomic) IBOutlet UILabel *medicateTypeLabel;
@property (weak, nonatomic) IBOutlet UILabel *usageLabel;
@property (weak, nonatomic) IBOutlet UILabel *dosageLabel;
@property (weak, nonatomic) IBOutlet UILabel *unitsLabel;


@end
