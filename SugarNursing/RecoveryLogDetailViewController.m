//
//  RecoveryLogDetailViewController.m
//  SugarNursing
//
//  Created by Dan on 14-11-20.
//  Copyright (c) 2014年 Tisson. All rights reserved.
//

#import "RecoveryLogDetailViewController.h"
#import "BasicCell.h"
#import "CommentCell.h"
#import "SensationCell.h"
#import "FieldCell.h"
#import "MedicateCell.h"
#import "DietCell.h"
#import "ExerciseCell.h"
#import "LogSectionHeaderView.h"
#import <MBProgressHUD.h>
#import "SWTableViewCell+RigthButtons.h"
#import "SwipeView.h"


static NSString *BasicCellIdentifier = @"BasicCell";
static NSString *CommentCellIdentifier = @"CommentCell";
static NSString *SensationCellIdentifier = @"SensationCell";
static NSString *FieldCellIdentifier = @"FieldCell";

static NSString *MediacteCellIdentifier = @"MedicateCell";
static NSString *DietCellIdentifier = @"DietCell";
static NSString *ExerciseCellIndentifier = @"ExerciseCell";

static NSString *SectionHeaderViewIdentifier = @"SectionHeaderViewIdentifier";


#define HEADER_HEIGHT 30



@interface RecoveryLogDetailViewController ()<SwipeViewDataSource, SwipeViewDelegate, UITableViewDataSource, UITableViewDelegate, UITabBarDelegate, UIActionSheetDelegate, UINavigationControllerDelegate, LogSectionHeaderViewDelegate, SWTableViewCellDelegate, UIPickerViewDataSource, UIPickerViewDelegate>{
    MBProgressHUD *hud;
}

@property (weak, nonatomic) IBOutlet SwipeView *swipeView;
@property (weak, nonatomic) IBOutlet UITabBar *tabBar;
@property (strong, nonatomic) UITableView *tableView;
@property (strong, nonatomic) UIActionSheet *sheet;

@property (weak, nonatomic) IBOutlet UIDatePicker *datePicker;
@property (strong, nonatomic) IBOutlet UIView *datePickerView;
@property (strong, nonatomic) IBOutlet UIView *pickerViewWrapper;
@property (weak, nonatomic) IBOutlet UIPickerView *pickerView;

@property (strong, nonatomic) NSIndexPath *selectedIndexPath;

@property (strong, nonatomic) NSMutableArray *trackerArray;
@property (strong, nonatomic) NSMutableArray *medicateArray;
@property (strong, nonatomic) NSMutableArray *dietArray;
@property (strong, nonatomic) NSMutableArray *exerciseArray;
@property (strong, nonatomic) NSMutableArray *medicationData;
@property (strong, nonatomic) NSMutableArray *dietData;
@property (strong, nonatomic) NSMutableArray *exerciseData;


@end

@implementation RecoveryLogDetailViewController

- (void)dataSetup
{
    self.trackerArray = [[NSMutableArray alloc] initWithCapacity:10];
    self.medicateArray = [[NSMutableArray alloc] initWithCapacity:10];
    self.dietArray = [[NSMutableArray alloc] initWithCapacity:10];
    self.exerciseArray = [[NSMutableArray alloc] initWithCapacity:10];
    self.medicationData = [[NSMutableArray alloc] initWithCapacity:10];
    self.dietData = [[NSMutableArray alloc] initWithCapacity:10];
    self.exerciseData = [[NSMutableArray alloc] initWithCapacity:10];
    self.selectedIndexPath = nil;
    
    NSDate *currentDate = [NSDate date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    NSDateFormatter *timeFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"YYYY-MM-dd"];
    [timeFormatter setDateFormat:@"HH:mm"];
    NSString *currentDateString = [dateFormatter stringFromDate:currentDate];
    NSString *currentTimeString = [timeFormatter stringFromDate:currentDate];
    
    // Default Setting
    NSArray *trackerDefault = @[@"血糖",@"其他",currentDateString,currentTimeString,@"",@""];
    [self.trackerArray addObjectsFromArray:trackerDefault];
    
    NSArray *medicateDefault = @[currentDateString, currentTimeString, @"",[@[@[@"药品名称",@"用法",@"用量",@"单位"]] mutableCopy],[@[@[@"药品名称",@"用法",@"用量",@"单位"]] mutableCopy]];
    [self.medicateArray addObjectsFromArray:medicateDefault];
    
    NSArray *dietDefault = @[currentDateString,currentTimeString,@"早餐",@"",[@[@[@"食物名称",@"用量",@"单位"]] mutableCopy]];
    [self.dietArray addObjectsFromArray:dietDefault];
    
    NSArray *exerciseDefault = @[currentDateString,currentTimeString,@"",[@[@[@"运动项目",@"时长",@"单位"]] mutableCopy]];
    [self.exerciseArray addObjectsFromArray:exerciseDefault];
    
    // Medication data
    NSArray *medicateDataDefault = @[
                                     @{@"胰岛素":@[@"格列齐特",@"格列齐特缓释片",@"格列美脲片",@"格列本脲片",@"阿卡波糖",@"罗格列酮"],
                                       @"降糖药":@[@"诺和锐30",@"诺和锐",@"诺和平",@"诺和灵",@"诺和灵30R",@"诺和灵50R"]
                                       },
                                     @[@"口服",@"注射"],
                                     @[@"1",@"2",@"3",@"4",@"5",@"6",@"7",@"8",@"9",@"10"],
                                     @[@"片",@"丸",@"支"]];
    [self.medicationData addObjectsFromArray:medicateDataDefault];
    
    NSArray *dietDataDefault = @[
                                 @[@"主食",@"蔬菜",@"果实",@"肉类",@"奶制品"],
                             @[@"50",@"50",@"50",@"50",@"50",@"50",@"50",@"50",@"50",@"50",@"50",@"50",@"50",@"50",@"50",@"50",@"50",@"50",@"50",@"50",@"50"],
                                 @[@"克",@"千克"]];
    [self.dietData addObjectsFromArray:dietDataDefault];
    
    NSArray *exerciseDataDefault = @[
                                     @[@"轻体力运动",@"中体力运动",@"强体力运动"],
                                     @[@"10",@"15",@"20",@"30",@"40",@"50",@"60"],
                                     @[@"分钟",@"小时"]];
    [self.exerciseData addObjectsFromArray:exerciseDataDefault];
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self dataSetup];
    
    switch (self.recoveryLogStatus) {
        case RecoveryLogStatusAdd:
        {
            self.title = NSLocalizedString(@"Add New Recovery Record", nil);
            self.tabBar.hidden = NO;
            self.tabBar.selectedItem = [self.tabBar.items objectAtIndex:0];
            break;
        }
        case RecoveryLogStatusEdit:
        {
            self.title = NSLocalizedString(@"Edit Recovery Record", nil);
            self.tabBar.hidden = YES;
            break;
        }
    }
    [self configureSaveBtn];
    
}

- (void)configureSaveBtn
{
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(save:)];
}

- (void)save:(id)sender
{
    
}

- (void)setExtraCellLineHidden
{
    UIView *helperView = [UIView new];
    helperView.backgroundColor = [UIColor clearColor];
    [self.tableView setTableFooterView:helperView];
}

- (void)registerCellAndSectionHeaderViewForTableView
{
    // Cell Registeration
    [self.tableView registerNib:[UINib nibWithNibName:@"BasicCell" bundle:nil] forCellReuseIdentifier:BasicCellIdentifier];
    [self.tableView registerNib:[UINib nibWithNibName:@"CommentCell" bundle:nil] forCellReuseIdentifier:CommentCellIdentifier];
    [self.tableView registerNib:[UINib nibWithNibName:@"SensationCell" bundle:nil] forCellReuseIdentifier:SensationCellIdentifier];
    [self.tableView registerNib:[UINib nibWithNibName:@"FieldCell" bundle:nil] forCellReuseIdentifier:FieldCellIdentifier];
    [self.tableView registerNib:[UINib nibWithNibName:@"MedicateCell" bundle:nil] forCellReuseIdentifier:MediacteCellIdentifier];
    [self.tableView registerNib:[UINib nibWithNibName:@"DietCell" bundle:nil] forCellReuseIdentifier:DietCellIdentifier];
    [self.tableView registerNib:[UINib nibWithNibName:@"ExerciseCell" bundle:nil] forCellReuseIdentifier:ExerciseCellIndentifier];
    
    // Section HeaderView Registeration
    [self.tableView registerNib:[UINib nibWithNibName:@"LogSectionHeaderView" bundle:nil] forHeaderFooterViewReuseIdentifier:SectionHeaderViewIdentifier];
}

#pragma mark - TabbarDelegate

- (void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item
{
    [self.swipeView scrollToItemAtIndex:[self.tabBar.items indexOfObject:item] duration:0];
}

#pragma mark - SwipeViewDataSource/Delegate

- (NSInteger)numberOfItemsInSwipeView:(SwipeView *)swipeView
{
    return self.recoveryLogStatus == RecoveryLogStatusAdd ? 4 : 1;
}

- (UIView *)swipeView:(SwipeView *)swipeView viewForItemAtIndex:(NSInteger)index reusingView:(UIView *)view
{
    UIView *itemView;
    if (self.recoveryLogStatus == RecoveryLogStatusAdd) {
        switch (index) {
            case 0:
                itemView = [[NSBundle mainBundle] loadNibNamed:@"detect" owner:self options:nil][0];
                if ([itemView isKindOfClass:[UITableView class]]) {
                    self.tableView = (UITableView *)itemView;
                    self.tableView.tag = 0;
                    
                }
                break;
                
            case 1:
                itemView = [[NSBundle mainBundle] loadNibNamed:@"drug" owner:self options:nil][0];
                if ([itemView isKindOfClass:[UITableView class]]) {
                    self.tableView = (UITableView *)itemView;
                    self.tableView.tag = 1;
                    
                }
                break;
                
            case 2:
                itemView = [[NSBundle mainBundle] loadNibNamed:@"diet" owner:self options:nil][0];
                if ([itemView isKindOfClass:[UITableView class]]) {
                    self.tableView = (UITableView *)itemView;
                    self.tableView.tag = 2;
                    
                }
                break;
            case 3:
                itemView = [[NSBundle mainBundle] loadNibNamed:@"exercise" owner:self options:nil][0];
                if ([itemView isKindOfClass:[UITableView class]]) {
                    self.tableView = (UITableView *)itemView;
                    self.tableView.tag = 3;
                    
                }
                break;
        }
    }else{
        itemView = [[NSBundle mainBundle] loadNibNamed:self.recordLog.logType owner:self options:nil][0];
        if ([itemView isKindOfClass:[UITableView class]]) {
            self.tableView = (UITableView *)itemView;
            self.tableView.tag = self.recoveryLogType;
        }
    }
    
    // InitialTableView
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    [self setExtraCellLineHidden];
    [self registerCellAndSectionHeaderViewForTableView];
    
    return itemView;
}

- (CGSize)swipeViewItemSize:(SwipeView *)swipeView
{
    return swipeView.bounds.size;
}

- (void)swipeViewDidEndDecelerating:(SwipeView *)swipeView
{
    self.tabBar.selectedItem = [self.tabBar.items objectAtIndex:swipeView.currentItemIndex];
    self.tableView = (UITableView *)swipeView.currentItemView;
}

#pragma mark - TableViewDelegate/DataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    switch (tableView.tag) {
        case 0:
            return 1;
        case 1:
            return 3;
        case 2:
            return 2;
        case 3:
            return 2;

    }
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger count = 0;
    switch (tableView.tag) {
        case 0:
            count = 7;
            break;
        case 1:
            switch (section) {
                case 0:
                    count = 3;
                    break;
                case 1:
                    count = [self.medicateArray[3] count];
                    break;
                case 2:
                    count = [self.medicateArray[4] count];

                    break;
            }
            break;
        case 2:
            if (section == 0) {
                count =  4;
            } else return count = [self.dietArray[4] count];
            break;
        case 3:
            if (section == 0) {
                count = 3;
            } else return count = [self.exerciseArray[3] count];
            break;
    }
    return count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == 0) {
        return 0;
    }
    else return HEADER_HEIGHT;
    
}


- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if (section == 0) {
        return nil;
    }
    
    LogSectionHeaderView *headerView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:SectionHeaderViewIdentifier];
    [self configureTableview:tableView withSectionHeaderView:headerView inSection:section];
    return headerView;
}

- (void)configureTableview:(UITableView *)tableView withSectionHeaderView:(LogSectionHeaderView *)headerView inSection:(NSInteger)section
{
    headerView.tableView = tableView;
    headerView.delegate = self;
    headerView.section = section;
    switch (tableView.tag) {
        case 1:
            if (section == 1) {
                headerView.titleLabel.text = @"胰岛素";
            } else if (section == 2) {
                headerView.titleLabel.text = @"降糖药";
            }
            break;
        case 2:
            if (section == 1) {
                headerView.titleLabel.text = @"摄入食物";
            }
            break;
        case 3:
            if (section == 1) {
                headerView.titleLabel.text = @"运动数据";
            }
            break;
        default:
            break;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat cellHeight;
    switch (tableView.tag) {
        case 0:
            if (indexPath.row == 5) {
                cellHeight = 85;
            } else cellHeight = 44;
            break;
        default:
            cellHeight = 44;
            break;
    }
    return cellHeight;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    switch (tableView.tag) {
            
        case 0:
        {
    
            if (indexPath.row <= 3) {
                BasicCell *cell = [tableView dequeueReusableCellWithIdentifier:BasicCellIdentifier forIndexPath:indexPath];
                [self configureTableView:tableView withBasicCell:cell atIndexPath:indexPath];
                return cell;
            } else if (indexPath.row == 4) {
                CommentCell *cell = [tableView dequeueReusableCellWithIdentifier:CommentCellIdentifier forIndexPath:indexPath];
                return cell;
            } else if (indexPath.row == 5) {
                SensationCell *cell = [tableView dequeueReusableCellWithIdentifier:SensationCellIdentifier forIndexPath:indexPath];
                return cell;
            } else {
                FieldCell *cell = [tableView dequeueReusableCellWithIdentifier:FieldCellIdentifier forIndexPath:indexPath];
                return cell;
            }
            break;
        }

        case 1:
        {
            if (indexPath.section == 0) {
                
                if (indexPath.row == 2) {
                    CommentCell *cell = [tableView dequeueReusableCellWithIdentifier:CommentCellIdentifier forIndexPath:indexPath];
                    return cell;
                } else {
                    BasicCell *cell = [tableView dequeueReusableCellWithIdentifier:BasicCellIdentifier forIndexPath:indexPath];
                    [self configureTableView:tableView withBasicCell:cell atIndexPath:indexPath];
                    return cell;
                }
            }
            else {
                MedicateCell *cell = [tableView dequeueReusableCellWithIdentifier:MediacteCellIdentifier forIndexPath:indexPath];
                [self configureTableView:tableView withMedicateCell:cell atIndexPath:indexPath];
                return cell;
                
            }
            
            
            break;
        }
            
        case 2:
        {
            switch (indexPath.section) {
                case 0:
                    if (indexPath.row == 3) {
                        CommentCell *cell = [tableView dequeueReusableCellWithIdentifier:CommentCellIdentifier forIndexPath:indexPath];
                        return cell;
                    } else {
                        BasicCell *cell = [tableView dequeueReusableCellWithIdentifier:BasicCellIdentifier forIndexPath:indexPath];
                        [self configureTableView:tableView withBasicCell:cell atIndexPath:indexPath];
                        return cell;
                    }
                    break;
                    
                case 1:
                {
                    DietCell *cell = [tableView dequeueReusableCellWithIdentifier:DietCellIdentifier forIndexPath:indexPath];
                    [self configureTableView:tableView withDietCell:cell atIndexPath:indexPath];
                    return cell;
                    break;
                }
            }
            
            break;
        }
            
        case 3:
        {
            switch (indexPath.section) {
                    
                case 0:
                    
                    if (indexPath.row == 2) {
                        CommentCell *cell = [tableView dequeueReusableCellWithIdentifier:CommentCellIdentifier forIndexPath:indexPath];
                        return cell;
                    } else {
                        BasicCell *cell = [tableView dequeueReusableCellWithIdentifier:BasicCellIdentifier forIndexPath:indexPath];
                        [self configureTableView:tableView withBasicCell:cell atIndexPath:indexPath];
                        return cell;
                    }
                    
                    break;
                    
                case 1:
                {
                    ExerciseCell *cell = [tableView dequeueReusableCellWithIdentifier:ExerciseCellIndentifier forIndexPath:indexPath];
                    [self configureTableView:tableView withExerciseCell:cell atIndexPath:indexPath];
                    return cell;
                    break;
                }
            }
           
        }
    }
    
    return nil;

}

- (void)configureTableView:(UITableView *)tableView withMedicateCell:(MedicateCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    [cell addRightButtons];
    [cell addLeftButtons];
    cell.delegate = self;
    
    switch (indexPath.section) {
        case 1:
            if (!indexPath.row == 0) {
                cell.medicateTypeLabel.textColor = [UIColor lightGrayColor];
                cell.usageLabel.textColor = [UIColor lightGrayColor];
                cell.dosageLabel.textColor = [UIColor lightGrayColor];
                cell.unitsLabel.textColor = [UIColor lightGrayColor];
            }
            
            cell.medicateTypeLabel.text = self.medicateArray[3][indexPath.row][0];
            cell.usageLabel.text = self.medicateArray[3][indexPath.row][1];
            cell.dosageLabel.text = self.medicateArray[3][indexPath.row][2];
            cell.unitsLabel.text = self.medicateArray[3][indexPath.row][3];

            break;
        case 2:
            if (!indexPath.row == 0) {
                cell.medicateTypeLabel.textColor = [UIColor lightGrayColor];
                cell.usageLabel.textColor = [UIColor lightGrayColor];
                cell.dosageLabel.textColor = [UIColor lightGrayColor];
                cell.unitsLabel.textColor = [UIColor lightGrayColor];
            }
            
            cell.medicateTypeLabel.text = self.medicateArray[4][indexPath.row][0];
            cell.usageLabel.text = self.medicateArray[4][indexPath.row][1];
            cell.dosageLabel.text = self.medicateArray[4][indexPath.row][2];
            cell.unitsLabel.text = self.medicateArray[4][indexPath.row][3];
            break;
        default:
            break;
    }
}

- (void)configureTableView:(UITableView *)tableView withDietCell:(DietCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    [cell addRightButtons];
    [cell addLeftButtons];
    cell.delegate = self;
    
    switch (indexPath.section) {
        case 1:
        {
            if (!indexPath.row == 0) {
                cell.foodNameLabel.textColor = [UIColor lightGrayColor];
                cell.dosageLabel.textColor = [UIColor lightGrayColor];
                cell.unitsLabel.textColor= [UIColor lightGrayColor];
            }
            
            cell.foodNameLabel.text = self.dietArray[4][indexPath.row][0];
            cell.dosageLabel.text = self.dietArray[4][indexPath.row][1];
            cell.unitsLabel.text = self.dietArray[4][indexPath.row][2];
            break;
        }
    }
}

- (void)configureTableView:(UITableView *)tableView withExerciseCell:(ExerciseCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    [cell addRightButtons];
    [cell addLeftButtons];
    cell.delegate = self;
    
    switch (indexPath.section) {
        case 1:
        {
            if (!indexPath.row == 0) {
                cell.exerciseNameLabel.textColor = [UIColor lightGrayColor];
                cell.timeLabel.textColor = [UIColor lightGrayColor];
                cell.unitsLabel.textColor = [UIColor lightGrayColor];
            }
            
            cell.exerciseNameLabel.text = self.exerciseArray[3][indexPath.row][0];
            cell.timeLabel.text = self.exerciseArray[3][indexPath.row][1];
            cell.unitsLabel.text = self.exerciseArray[3][indexPath.row][2];
            
            break;
        }
        default:
            break;
    }
}

- (void)configureTableView:(UITableView *)tableView withBasicCell:(BasicCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    switch (tableView.tag) {
            
        case 0:
            switch (indexPath.row) {
                case 0:
                    cell.titleLabel.text = @"检测结果";
                    cell.detailLabel.text = self.trackerArray[0];
                    break;
                case 1:
                    cell.titleLabel.text = @"检测设备";
                    cell.detailLabel.text = self.trackerArray[1];
                    break;
                case 2:
                    cell.titleLabel.text = @"检测日期";
                    cell.detailLabel.text = self.trackerArray[2];
                    break;
                case 3:
                    cell.titleLabel.text = @"检测时间";
                    cell.detailLabel.text = self.trackerArray[3];
                    break;
                default:
                    break;
            }
            break;
        case 1:
            switch (indexPath.row) {
                case 0:
                    cell.titleLabel.text = @"用药日期";
                    cell.detailLabel.text = self.medicateArray[0];
                    break;
                case 1:
                    cell.titleLabel.text = @"用药时间";
                    cell.detailLabel.text = self.medicateArray[1];
                    break;

                default:
                    break;
            }
            break;
        case 2:
            switch (indexPath.row) {
                case 0:
                    cell.titleLabel.text = @"进餐日期";
                    cell.detailLabel.text = self.dietArray[0];
                    break;
                case 1:
                    cell.titleLabel.text = @"进餐时间";
                    cell.detailLabel.text = self.dietArray[1];
                    break;
                case 2:
                    cell.titleLabel.text = @"三餐情况";
                    cell.detailLabel.text = self.dietArray[2];
                    break;
                    
                default:
                    break;
            }
            break;
        case 3:
            switch (indexPath.row) {
                case 0:
                    cell.titleLabel.text = @"运动日期";
                    cell.detailLabel.text = self.exerciseArray[0];
                    break;
                case 1:
                    cell.titleLabel.text = @"开始时间";
                    cell.detailLabel.text = self.exerciseArray[1];
                    break;

                    
                default:
                    break;
            }
            break;
    }
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    // !important. Repoint to the current tableview
    self.selectedIndexPath = indexPath;
    self.tableView = tableView;
    
    switch (tableView.tag) {
        case 0:
            switch (indexPath.row) {
                case 0:
                    self.sheet = [[UIActionSheet alloc] initWithTitle:@"选择检测类型" delegate:self cancelButtonTitle:nil destructiveButtonTitle:@"取消" otherButtonTitles:@"血糖",@"糖化血红蛋白",nil];
                    [self.sheet showInView:self.view];
                    break;
                case 1:
                    self.sheet = [[UIActionSheet alloc] initWithTitle:@"选择检测设备" delegate:self cancelButtonTitle:nil destructiveButtonTitle:@"取消" otherButtonTitles:@"设备一",@"设备二",@"其他", nil];
                    [self.sheet showInView:self.view];
                    break;
                case 2:
                    [self showDatePickerHUDWithMode:UIDatePickerModeDate];
                    break;
                case 3:
                    [self showDatePickerHUDWithMode:UIDatePickerModeTime];
                    break;
                default:
                    break;
            }
            break;
        case 1:
            switch (indexPath.section) {
                case 0:
                    switch (indexPath.row) {
                        case 0:
                            [self showDatePickerHUDWithMode:UIDatePickerModeDate];
                            break;
                        case 1:
                            [self showDatePickerHUDWithMode:UIDatePickerModeTime];
                            break;
                        default:
                            break;
                    }
                    break;
                case 1:
                case 2:
                    if (indexPath.row == 0) {
                        return;
                    }
                    
                    [self showPickerViewHUD];
                    [self.pickerView reloadAllComponents];
                    break;
                    
                default:
                    break;
            }
            break;
            
        case 2:
            switch (indexPath.section) {
                case 0:
                    switch (indexPath.row) {
                        case 0:
                            [self showDatePickerHUDWithMode:UIDatePickerModeDate];
                            break;
                        case 1:
                            [self showDatePickerHUDWithMode:UIDatePickerModeTime];
                            break;
                        case 2:
                            self.sheet = [[UIActionSheet alloc] initWithTitle:@"选择用餐类型" delegate:self cancelButtonTitle:nil destructiveButtonTitle:@"取消" otherButtonTitles:@"早餐",@"午餐",@"晚餐",@"宵夜",nil];
                            [self.sheet showInView:self.view];
                            break;
                        default:
                            break;
                    }
                    break;
                case 1:
                    if (indexPath.row == 0) {
                        return;
                    }
                    [self showPickerViewHUD];
                    [self.pickerView reloadAllComponents];
                    break;
                    
                default:
                    break;
            }
            break;
        
        case 3:
            switch (indexPath.section) {
                case 0:
                    switch (indexPath.row) {
                        case 0:
                            [self showDatePickerHUDWithMode:UIDatePickerModeDate];
                            break;
                        case 1:
                            [self showDatePickerHUDWithMode:UIDatePickerModeTime];
                            break;
                        default:
                            break;
                    }
                    break;
                case 1:
                    if (indexPath.row == 0) {
                        return;
                    }
                    [self showPickerViewHUD];
                    [self.pickerView reloadAllComponents];
                    break;
                default:
                    break;
            }
            break;
    }
}

#pragma mark - SWTableViewDelegate

- (void)swipeableTableViewCell:(SWTableViewCell *)cell didTriggerRightUtilityButtonWithIndex:(NSInteger)index
{
    switch (index) {
        case 0:
        {
            NSIndexPath *cellIndexPath = [self.tableView indexPathForCell:cell];

            if ([cell isKindOfClass:[MedicateCell class]]) {
                switch (cellIndexPath.section) {
                    case 1:
                        if (cellIndexPath.row == 0) {
                            [cell hideUtilityButtonsAnimated:YES];
                        }else{
                            [self.medicateArray[3] removeObjectAtIndex:cellIndexPath.row];
                            [self.tableView deleteRowsAtIndexPaths:@[cellIndexPath] withRowAnimation:UITableViewRowAnimationLeft];
                        }
                        break;
                    case 2:
                        if (cellIndexPath.row == 0) {
                            return;
                        }else{
                            [self.medicateArray[4] removeObjectAtIndex:cellIndexPath.row];
                            [self.tableView deleteRowsAtIndexPaths:@[cellIndexPath] withRowAnimation:UITableViewRowAnimationLeft];
                        }
                        
                    default:
                        break;
                }
            } else if ([cell isKindOfClass:[DietCell class]]) {
                switch (cellIndexPath.section) {
                    case 1:
                        if (cellIndexPath.row == 0) {
                            [cell hideUtilityButtonsAnimated:YES];
                        }else {
                            [self.dietArray[4] removeObjectAtIndex:cellIndexPath.row];
                            [self.tableView deleteRowsAtIndexPaths:@[cellIndexPath] withRowAnimation:UITableViewRowAnimationLeft];
                        }
                        break;
                        
                    default:
                        break;
                }
            } else if ([cell isKindOfClass:[ExerciseCell class]]){
                switch (cellIndexPath.section) {
                    case 1:
                        if (cellIndexPath.row == 0) {
                            [cell hideUtilityButtonsAnimated:YES];
                        }else{
                            [self.exerciseArray[3] removeObjectAtIndex:cellIndexPath.row];
                            [self.tableView deleteRowsAtIndexPaths:@[cellIndexPath] withRowAnimation:UITableViewRowAnimationLeft];
                        }
                        break;
                        
                    default:
                        break;
                }
            }
            
            
           

            break;
        }
    }
}

- (void)swipeableTableViewCell:(SWTableViewCell *)cell didTriggerLeftUtilityButtonWithIndex:(NSInteger)index
{
    switch (index) {
        case 0:
            [cell hideUtilityButtonsAnimated:YES];
            break;
            
        default:
            break;
    }
}


#pragma mark - LogSectionHeaderViewDelegate

- (void)LogSectionHeaderView:(LogSectionHeaderView *)headerView sectionToggleAdd:(NSInteger)section
{
    self.tableView = headerView.tableView;
    
    switch (self.tableView.tag) {
        case 1:
            switch (headerView.section) {
                case 1:
                {
                    NSInteger insertRow = [self.medicateArray[3] count];
                    NSIndexPath *insertIndexPath = [NSIndexPath indexPathForRow:insertRow inSection:headerView.section];
                    [self.medicateArray[3] addObject:[@[@"选择药品",@"选择用法",@"选择用量",@"选择单位"] mutableCopy]];
                    [self.tableView insertRowsAtIndexPaths:@[insertIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                
                    break;
                }
                case 2:
                {
                    NSInteger insertRow = [self.medicateArray[4] count];
                    NSIndexPath *insertIndexPath = [NSIndexPath indexPathForRow:insertRow inSection:headerView.section];
                    [self.medicateArray[4] addObject:[@[@"选择药品",@"选择用法",@"选择用量",@"选择单位"] mutableCopy]];
                    [self.tableView insertRowsAtIndexPaths:@[insertIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                    break;
                }
                default:
                    break;
            }
            break;
        case 2:
            switch (headerView.section) {
                case 1:
                {
                    NSInteger insertRow = [self.dietArray[4] count];
                    NSIndexPath *insertIndexPath = [NSIndexPath indexPathForRow:insertRow inSection:headerView.section];
                    [self.dietArray[4] addObject:[@[@"食物名称",@"用量",@"单位"] mutableCopy]];
                    [self.tableView insertRowsAtIndexPaths:@[insertIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                     
                    break;
                }
                default:
                    break;
            }
            break;
        case 3:
            switch (headerView.section) {
                case 1:
                {
                    NSInteger insertRow = [self.exerciseArray[3] count];
                    NSIndexPath *insertIndexPath = [NSIndexPath indexPathForRow:insertRow inSection:headerView.section];
                    [self.exerciseArray[3] addObject:[@[@"运动名称",@"时长",@"单位"] mutableCopy]];
                    [self.tableView insertRowsAtIndexPaths:@[insertIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                    break;
                }
                default:
                    break;
            }
        default:
            break;
    }

}


#pragma mark - DatePickerHUD

- (void)showDatePickerHUDWithMode:(UIDatePickerMode )mode
{
    hud = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
    [self.navigationController.view addSubview:hud];
    
    self.datePicker.datePickerMode = mode;
    hud.margin = 0;
    hud.customView = self.datePickerView;
    hud.mode = MBProgressHUDModeCustomView;
    [hud show:YES];
}

#pragma mark - PickerViewHUD

- (void)showPickerViewHUD
{
    hud = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
    [self.navigationController.view addSubview:hud];
    
    hud.margin = 0;
    hud.customView = self.pickerViewWrapper;
    hud.mode = MBProgressHUDModeCustomView;
    [hud show:YES];
}
- (IBAction)pickerViewAction:(id)sender
{
    [hud hide:YES afterDelay:0.25];
}

#pragma mark - PickerViewDataSource/Delegate

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    NSInteger components = 0;
    switch (self.tableView.tag) {
        case 1:
            switch (self.selectedIndexPath.section) {
                case 1:
                case 2:
                    components = self.medicationData.count;
                    break;
                    
                default:
                    break;
            }
            break;
        case 2:
            switch (self.selectedIndexPath.section) {
                case 1:
                    components = self.dietData.count;
                    break;
                    
                default:
                    break;
            }
            break;
        case 3:
            switch (self.selectedIndexPath.section) {
                case 1:
                    components = self.exerciseData.count;
                    break;
                    
                default:
                    break;
            }
            break;
        default:
            break;
    }
    return components;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    NSInteger rows = 0;
    switch (self.tableView.tag) {
        case 1:
            switch (self.selectedIndexPath.section) {
                case 1:
                    if (component == 0) {
                        rows = [self.medicationData[component][@"胰岛素"] count];
                    }else rows = [self.medicationData[component] count];
                    break;
                case 2:
                    if (component == 0) {
                        rows = [self.medicationData[component][@"降糖药"] count];
                    }else rows = [self.medicationData[component] count];
                default:
                    break;
            }
            break;
        case 2:
            switch (self.selectedIndexPath.section) {
                case 1:
                    rows = [self.dietData[component] count];
                    break;
                    
                default:
                    break;
            }
            break;
        case 3:
            switch (self.selectedIndexPath.section) {
                case 1:
                    rows = [self.exerciseData[component] count];
                    break;
                    
                default:
                    break;
            }
            break;
        default:
            break;
    }
    return rows;
}

- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view
{
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.font = [UIFont systemFontOfSize:16];
    titleLabel.textColor = [UIColor blackColor];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    
    switch (self.tableView.tag) {
        case 1:
            switch (self.selectedIndexPath.section) {
                case 1:
                {
                    if (component == 0) {
                        titleLabel.text = self.medicationData[component][@"胰岛素"][row];
                    }
                    else titleLabel.text = self.medicationData[component][row];

                    break;
                }
                case 2:
                {
                    if (component == 0) {
                        titleLabel.text = self.medicationData[component][@"降糖药"][row];
                    }
                    else titleLabel.text = self.medicationData[component][row];
                    
                    break;
                }
                default:
                    break;
            }
            break;
        case 2:
            switch (self.selectedIndexPath.section) {
                case 1:
                {
                    titleLabel.text = self.dietData[component][row];
                    break;
                }
                default:
                    break;
            }
            break;
        case 3:
            switch (self.selectedIndexPath.section) {
                case 1:
                {
                    titleLabel.text = self.exerciseData[component][row];
                    break;
                }
                default:
                    break;
            }
            break;
        default:
            break;
    }
    return titleLabel;
    
}

- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component
{
    CGFloat widthForComponent;
    if (component == 0) {
        widthForComponent = 126;
    } else widthForComponent = 46;
    return widthForComponent;
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    switch (self.tableView.tag) {
        case 1:
            switch (self.selectedIndexPath.section) {
                case 1:
                {
                    
                    if (component == 0) {
                        [self.medicateArray[3][self.selectedIndexPath.row] replaceObjectAtIndex:component withObject:self.medicationData[component][@"胰岛素"][row]];
                    }else [self.medicateArray[3][self.selectedIndexPath.row] replaceObjectAtIndex:component withObject:self.medicationData[component][row]];
                   
                    break;
                }
                case 2:
                {
                    if (component == 0) {
                        [self.medicateArray[4][self.selectedIndexPath.row] replaceObjectAtIndex:component withObject:self.medicationData[component][@"降糖药"][row]];
                    }else [self.medicateArray[4][self.selectedIndexPath.row] replaceObjectAtIndex:component withObject:self.medicationData[component][row]];
                }
                default:
                    break;
            }
            break;
            
        case 2:
            switch (self.selectedIndexPath.section) {
                case 1:
                {
                    [self.dietArray[4][self.selectedIndexPath.row] replaceObjectAtIndex:component withObject:self.dietData[component][row]];
                    break;
                }
                default:
                    break;
            }
            break;
        case 3:
            switch (self.selectedIndexPath.section) {
                case 1:
                {
                    [self.exerciseArray[3][self.selectedIndexPath.row] replaceObjectAtIndex:component withObject:self.exerciseData[component][row]];
                    break;
                }
                default:
                    break;
            }
            break;
        default:
            break;
    }
    
     [self.tableView reloadRowsAtIndexPaths:@[self.selectedIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    
}

#pragma mark - ActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch (self.tableView.tag) {
        case 0:
            switch (self.selectedIndexPath.section) {
                case 0:
                    switch (self.selectedIndexPath.row) {
                        case 0:
                        case 1:
                            if (buttonIndex == 0) {
                                return;
                            }else{
                                [self.trackerArray replaceObjectAtIndex:self.selectedIndexPath.row withObject:[actionSheet buttonTitleAtIndex:buttonIndex]];
                                [self.tableView reloadRowsAtIndexPaths:@[self.selectedIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                            }
                            break;
                    }
                    break;
                    
                default:
                    break;
            }
            break;
        case 2:
            switch (self.selectedIndexPath.section) {
                case 0:
                    switch (self.selectedIndexPath.row) {
                        case 2:
                            if (buttonIndex == 0) {
                                return;
                            }else{
                                [self.dietArray replaceObjectAtIndex:self.selectedIndexPath.row withObject:[actionSheet buttonTitleAtIndex:buttonIndex]];
                                [self.tableView reloadRowsAtIndexPaths:@[self.selectedIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                            }
                            break;
                            
                    }
                    break;
                    
                default:
                    break;
            }
            break;
            
        
        default:
            break;
    }
    
}



- (IBAction)datePickerSelected:(id)sender
{
    UIDatePicker *datePicker = (UIDatePicker *)sender;
    NSDate *date = [datePicker date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];

    if (datePicker.datePickerMode == UIDatePickerModeDate) {
        [dateFormatter setDateFormat:@"YYYY-MM-dd"];
    } else if (datePicker.datePickerMode == UIDatePickerModeTime) {
        [dateFormatter setDateFormat:@"HH:mm"];
    }
    
    NSString *dateString = [dateFormatter stringFromDate:date];
    
    switch (self.tableView.tag) {
        case 0:
            
            [self.trackerArray replaceObjectAtIndex:self.selectedIndexPath.row withObject:dateString];
            [self.tableView reloadRowsAtIndexPaths:@[self.selectedIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            
            break;
        case 1:
            
            [self.medicateArray replaceObjectAtIndex:self.selectedIndexPath.row withObject:dateString];
            [self.tableView reloadRowsAtIndexPaths:@[self.selectedIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            
            break;
        case 2:
            
            [self.dietArray replaceObjectAtIndex:self.selectedIndexPath.row withObject:dateString];
            [self.tableView reloadRowsAtIndexPaths:@[self.selectedIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            
            break;
        case 3:
            
            [self.exerciseArray replaceObjectAtIndex:self.selectedIndexPath.row withObject:dateString];
            [self.tableView reloadRowsAtIndexPaths:@[self.selectedIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        default:
            break;
    }
    
    
}

- (IBAction)datePickerBtnAction:(id)sender
{
    [hud hide:YES afterDelay:0.25];
}



@end
