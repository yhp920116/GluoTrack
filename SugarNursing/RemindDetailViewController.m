//
//  WarningDetailViewController.m
//  SugarNursing
//
//  Created by Dan on 14-11-23.
//  Copyright (c) 2014年 Tisson. All rights reserved.
//

#import "RemindDetailViewController.h"
#import <MBProgressHUD.h>

@interface RemindDetailViewController (){
    MBProgressHUD *hud;
}

@property (strong, nonatomic) NSIndexPath *selectedIndexPath;

@end

@implementation RemindDetailViewController

- (void)awakeFromNib
{
    self.pickerData = [NSMutableArray array];
    NSArray *data = @[
                      @[
                          @[@[@"胰岛素",@"降糖药"],@[@"药品1",@"药品2",@"药品3",@"药品4",@"药品5",]],
                          @[],
                          @[@[@"单位1",@"单位2",@"单位3",@"单位4"]],
                          @[@[@"方法1",@"方法2",@"方法3",@"方法4",]],
                        ],
                      @[@[]],
                      @[
                          @[@[@"每天",@"每2天",@"每三天"]],
                          @[@[@"1次",@"2次",@"3次",@"4次",]],
                          @[],],
                      ];
    
    [self.pickerData addObjectsFromArray:data];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{

    self.selectedIndexPath = indexPath;
    NSLog(@"%@",indexPath);
    switch (indexPath.section) {
        case 0:
            switch (indexPath.row) {
                case 1:
                    [self.doseFiled becomeFirstResponder];
                    return;
                case 0:
                case 2:
                case 3:
                    hud = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
                    [self.navigationController.view addSubview:hud];
                    
                    hud.customView = self.pickerView;
                    hud.mode = MBProgressHUDModeCustomView;
                    [hud show:YES];
                    [self.pickerView reloadAllComponents];
                    break;
            }
            break;
           
        case 1:
            hud = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
            [self.navigationController.view addSubview:hud];
            
            hud.customView = self.datePicker;
            hud.mode = MBProgressHUDModeCustomView;
            [hud show:YES];
            break;
        case 2:
            switch (indexPath.row) {
                case 0:
                case 1:
                    hud = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
                    [self.navigationController.view addSubview:hud];
                    
                    hud.customView = self.pickerView;
                    hud.mode = MBProgressHUDModeCustomView;
                    [hud show:YES];
                    [self.pickerView reloadAllComponents];
                    break;
                case 2:
                    hud = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
                    [self.navigationController.view addSubview:hud];
                    
                    hud.customView = self.timePicker;
                    hud.mode = MBProgressHUDModeCustomView;
                    [hud show:YES];
                    break;
            }
            break;
    }
    
    [self.doseFiled resignFirstResponder];
}

- (IBAction)datePickerAction:(id)sender
{
    NSDate *selectDate = [self.datePicker date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd"];
    NSString *selectDateString = [dateFormatter stringFromDate:selectDate];
    
    self.dateLabel.text = selectDateString;
    
    [self.tableView deselectRowAtIndexPath:self.selectedIndexPath animated:YES];
    [hud hide:YES afterDelay:0.25];
}
- (IBAction)timePickerAction:(id)sender
{
    NSDate *selectDate = [self.timePicker date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"HH-mm"];
    NSString *selectTimeString = [dateFormatter stringFromDate:selectDate];
    
    self.timeLabel.text = selectTimeString;
    
    [self.tableView deselectRowAtIndexPath:self.selectedIndexPath animated:YES];
    [hud hide:YES afterDelay:0.25];
}


#pragma mark - PickerViewDelegate/DataSource

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    NSInteger components = [self.pickerData[self.selectedIndexPath.section][self.selectedIndexPath.row] count];
    return components;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    NSInteger rows = [self.pickerData[self.selectedIndexPath.section][self.selectedIndexPath.row][component] count];
    return rows;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    NSString *title = self.pickerData[self.selectedIndexPath.section][self.selectedIndexPath.row][component][row];
    return title;
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    switch (self.selectedIndexPath.section) {
        case 0:
            switch (self.selectedIndexPath.row) {
                case 0:
                    if (component == 0) {
                        self.drugTypeLabel.text = [self pickerView:self.pickerView titleForRow:row forComponent:component];
                    }else {
                        self.drugNameLabel.text = [self pickerView:self.pickerView titleForRow:row forComponent:component];
                    }
                    break;
                case 2:
                    self.unitLabel.text = [self pickerView:self.pickerView titleForRow:row forComponent:component];
                    break;
                case 3:
                    self.usageLabel.text = [self pickerView:self.pickerView titleForRow:row forComponent:component];
                    break;
            }
            break;
        case 2:
            switch (self.selectedIndexPath.row) {
                case 0:
                    self.cycleLabel.text = [self pickerView:self.pickerView titleForRow:row forComponent:component];
                    break;
                case 1:
                    self.timesLabel.text = [self pickerView:self.pickerView titleForRow:row forComponent:component];
                    break;

            }
            break;
            
    }
    

    [self.tableView deselectRowAtIndexPath:self.selectedIndexPath animated:YES];
    
    [hud hide:YES afterDelay:0.25];
}




@end
