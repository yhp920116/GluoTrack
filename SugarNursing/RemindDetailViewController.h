//
//  WarningDetailViewController.h
//  SugarNursing
//
//  Created by Dan on 14-11-23.
//  Copyright (c) 2014年 Tisson. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RemindDetailViewController : UITableViewController<UIPickerViewDataSource, UIPickerViewDelegate>

@property (strong, nonatomic) NSMutableArray *pickerData;

@property (strong, nonatomic) IBOutlet UIPickerView *pickerView;
@property (strong, nonatomic) IBOutlet UIDatePicker *datePicker;
@property (strong, nonatomic) IBOutlet UIDatePicker *timePicker;


@property (weak, nonatomic) IBOutlet UITextField *doseFiled;
@property (weak, nonatomic) IBOutlet UILabel *drugTypeLabel;
@property (weak, nonatomic) IBOutlet UILabel *drugNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *unitLabel;
@property (weak, nonatomic) IBOutlet UILabel *usageLabel;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (weak, nonatomic) IBOutlet UILabel *cycleLabel;
@property (weak, nonatomic) IBOutlet UILabel *timesLabel;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;


@end
