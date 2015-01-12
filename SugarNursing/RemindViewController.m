//
//  WarningViewController.m
//  SugarNursing
//
//  Created by Dan on 14-11-23.
//  Copyright (c) 2014年 Tisson. All rights reserved.
//

#import "RemindViewController.h"
#import "RemindCell.h"
#import "ControlPlanCell.h"
#import "ControlHeaderView.h"


static NSString *SectionHeaderViewIdentifier = @"ControlHeaderViewIdentifier";


@interface RemindViewController ()

@property (strong, nonatomic) UITableView *tableView;
@property (strong, nonatomic) NSMutableArray *timeArray;

@end

@implementation RemindViewController

- (void)awakeFromNib
{
    self.dataArray = [NSMutableArray array];
    self.timeArray = [NSMutableArray array];
    
    NSArray *data = @[
                      @[@"其他",@"肝太乐片",@"每天服用",@"一天3次",@"每次2片"],
                      @[@"其他",@"复合维生素B",@"每天服用",@"一天3次",@"每次2片"],
                      ];
    NSArray *time = @[@"起床后",@"早餐前",@"早餐后1小时",@"早餐后1小时",@"早餐后2小时",@"早餐后2小时",@"午餐前",@"午餐后1小时",@"午餐后3小时",@"午餐3小时",@"晚餐前",@"晚餐后半小时",@"晚餐后1小时",@"晚餐后2小时",@"晚餐后3小时",@"睡觉前",];
    
    [self.dataArray addObjectsFromArray:data];
    [self.timeArray addObjectsFromArray:time];
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self.tabBar setSelectedItem:[self.tabBar items][0]];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"AddRemind"]) {
        [self.dataArray addObject:@[@"胰岛素",@"诺和平",@"每天四次",@"一天三次",@"每次三毫克"]];
    }
}

#pragma mark - SwipeViewDataSource/Delegate

- (NSInteger)numberOfItemsInSwipeView:(SwipeView *)swipeView
{
    return 2;
}

- (UIView *)swipeView:(SwipeView *)swipeView viewForItemAtIndex:(NSInteger)index reusingView:(UIView *)view
{
    UIView *itemView;
    switch (index) {
        case 0:
            itemView = [[NSBundle mainBundle] loadNibNamed:@"Remind" owner:self options:nil][0];
            if ([itemView isKindOfClass:[UITableView class]]) {
                [self configureItemView:itemView];
            }
            break;
        case 1:
            itemView = [[NSBundle mainBundle] loadNibNamed:@"ControlPlan" owner:self options:nil][0];
            if ([itemView isKindOfClass:[UITableView class]]) {
                [self configureItemView:itemView];
            }
        default:
            break;
    }
    
    return itemView;
}

- (CGSize)swipeViewItemSize:(SwipeView *)swipeView
{
    return self.swipeView.bounds.size;
}

- (void)configureItemView:(UIView *)itemView
{
    self.tableView = (UITableView *)itemView;
    switch (itemView.tag) {
        case 0:
        {
            [self.tableView registerNib:[UINib nibWithNibName:@"RemindCell" bundle:nil] forCellReuseIdentifier:@"RemindCell"];
            break;
        }
        case 1:
        {
            [self.tableView registerNib:[UINib nibWithNibName:@"ControlSectionHeaderView" bundle:nil] forHeaderFooterViewReuseIdentifier:SectionHeaderViewIdentifier];
            [self.tableView registerNib:[UINib nibWithNibName:@"ControlPlanCell" bundle:nil] forCellReuseIdentifier:@"ControlPlanCell"];
            break;
        }
    }
    
    
}

- (void)swipeViewDidEndDecelerating:(SwipeView *)swipeView
{
    self.tableView = (UITableView *)[swipeView itemViewAtIndex:swipeView.currentItemIndex];
    self.tabBar.selectedItem = [self.tabBar.items objectAtIndex:swipeView.currentItemIndex];
}

#pragma mark - TableViewDataSource


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger rows = 0;
    switch (tableView.tag) {
        case 0:
            rows = [self.dataArray count];
            break;
        case 1:
            rows = [self.timeArray count];
            break;
    }
    return rows;
}


- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    if (tableView.tag == 1) return nil;
    UIView *footerView = [[NSBundle mainBundle] loadNibNamed:@"Remind" owner:self options:0][1];
    return footerView;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if (tableView.tag == 0) return nil;
    
    ControlHeaderView *headerView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:SectionHeaderViewIdentifier];
    return headerView;
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (tableView.tag == 0) return 0;
    return 130;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    if (tableView.tag == 1) return 0;
    return 30;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (tableView.tag) {
        case 0:
        {
            RemindCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"RemindCell" forIndexPath:indexPath];
            [self configureWarningCell:cell indexPath:indexPath];
            return cell;
        }
        case 1:
        {
            ControlPlanCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"ControlPlanCell" forIndexPath:indexPath];
            [self configureControlPlanCell:cell indexPath:indexPath];
            return cell;
        }
            
        default:
            break;
    }
    return nil;
}

- (void)configureWarningCell:(RemindCell *)cell indexPath:(NSIndexPath *)indexPath
{
    cell.medicationTypeLabel.text = self.dataArray[indexPath.row][0];
    cell.medicationLabel.text = self.dataArray[indexPath.row][1];
    cell.medicateCycleLabel.text = self.dataArray[indexPath.row][2];
    cell.medicateTimeLabel.text = self.dataArray[indexPath.row][3];
    cell.medicateUsageLabel.text = self.dataArray[indexPath.row][4];
}

- (void)configureControlPlanCell:(ControlPlanCell *)cell indexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row % 2 == 0) {
        cell.controlPlanView.backgroundColor = [UIColor whiteColor];
    }
    cell.timeLabel.text = self.timeArray[indexPath.row];
    cell.timeLabel.font = [UIFont systemFontOfSize:12.0f];
}



#pragma mark - TableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat heightForRow;
    if (tableView.tag == 0) {
        heightForRow = 65;
    } else heightForRow = [self heightForBasicCellAtIndexPath:indexPath];
    return heightForRow;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 44.0f;
}

- (CGFloat)heightForBasicCellAtIndexPath:(NSIndexPath *)indexPath
{
    static ControlPlanCell *sizingCell = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sizingCell = [self.tableView dequeueReusableCellWithIdentifier:@"ControlPlanCell"];
    });
    [self configureControlPlanCell:sizingCell indexPath:indexPath];
    return [self calculateHeightForConfiguredSizingCell:sizingCell];
}

- (CGFloat)calculateHeightForConfiguredSizingCell:(UITableViewCell *)sizingCell
{
    sizingCell.bounds = CGRectMake(0.0f, 0.0, CGRectGetWidth(self.tableView.bounds), 0.0f);
    [sizingCell setNeedsLayout];
    [sizingCell layoutIfNeeded];
    
    CGSize size = [sizingCell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
    return size.height;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self performSegueWithIdentifier:@"ShowsDetail" sender:indexPath];
}

#pragma mark - TabBarDelegate
- (void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item
{
    [self.swipeView scrollToItemAtIndex:[self.tabBar.items indexOfObject:item] duration:0];
}

- (IBAction)AddRemind:(id)sender
{
    [self performSegueWithIdentifier:@"AddRemind" sender:sender];
}

- (IBAction)back:(UIStoryboardSegue *)segue
{
    
    [self.tableView reloadData];
}

- (IBAction)trash:(UIStoryboardSegue *)segue
{
    [self.dataArray removeLastObject];
    [self.tableView reloadData];
}


@end
