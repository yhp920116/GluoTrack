//
//  ControlEffectViewController.m
//  SugarNursing
//
//  Created by Dan on 14-11-21.
//  Copyright (c) 2014年 Tisson. All rights reserved.
//

#import "ControlEffectViewController.h"
#import "EvaluateCell.h"
#import "EffectCell.h"
#import <SSPullToRefresh.h>
#import "UtilsMacro.h"


@interface ControlEffectViewController ()<UITableViewDataSource, UITableViewDelegate,UIPickerViewDataSource,UIPickerViewDelegate, SSPullToRefreshViewDelegate>{
    MBProgressHUD *hud;
}


@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) IBOutlet UIPickerView *pickerView;
@property (strong, nonatomic) IBOutlet UIView *wrapperView;
@property (strong, nonatomic) SSPullToRefreshView *refreshView;

@property (strong, nonatomic) NSMutableArray *dataArray;
@property (strong, nonatomic) NSDictionary *countDayDic;
@property (strong, nonatomic) NSString *countDay;

@end

@implementation ControlEffectViewController

- (void)awakeFromNib
{
    self.countDay = @"7";
    self.dataArray = [NSMutableArray array];
    self.countDayDic = @{@"近三天":@"3",
                         @"近七天":@"7",
                         @"近两星期":@"14",
                         @"近一个月":@"30",
                         };
    NSArray *data = @[
                      @[@75,@"良好的血糖控制有利于身体各项机能的健康运行"],
                      @[@"空腹血糖",@14,@2,@5.8,@4.4,@4.8],
                      @[@"餐后血糖",@20,@4,@7.2,@6.3,@6.7],
                      @[@"糖化血红蛋白",@15,@2,@"6.5%",@"5.5%",@"6.2%"],
                      ];
    
    [self.dataArray addObjectsFromArray:data];
    
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.estimatedRowHeight = UITableViewAutomaticDimension;
}

- (void)viewDidLayoutSubviews
{
    if (self.refreshView == nil) {
        self.refreshView = [[SSPullToRefreshView alloc] initWithScrollView:self.tableView delegate:self];
        [self.refreshView startLoadingAndExpand:YES animated:YES];
    }
}

#pragma mark - SSPUllToRefreshViewDelegate
- (void)pullToRefreshViewDidStartLoading:(SSPullToRefreshView *)view
{
    [self getControlEffectData];
}

- (void)getControlEffectData
{
    
    NSDictionary *parameters = @{@"method":@"queryConclusion",
                                 @"sign":@"sign",
                                 @"sessionId":[NSString sessionID],
                                 @"linkManId":[NSString linkmanID],
                                 @"countDay":self.countDay};
    [GCRequest userGetControlEffectWithParameters:parameters withBlock:^(NSDictionary *responseData, NSError *error) {
        
        [self.refreshView finishLoading];
    }];
}

#pragma mark - tableViewDelegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.dataArray count]+1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 0) {
        EvaluateCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"EvaluateCell" forIndexPath:indexPath];
        [self configureEvaluateCell:cell forIndexPath:indexPath];
        return cell;
    } else if (indexPath.row == 1) {
        UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"Basic" forIndexPath:indexPath];
        cell.textLabel.text = @"选择周期";
        cell.detailTextLabel.text = @"近7天";
        return cell;
    } else {
        EffectCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"EffectCell" forIndexPath:indexPath];
        [self configureEffectCell:cell forIndexPath:indexPath];
        return cell;
    }
    return nil;
}

- (void)setupConstraintsWithCell:(UITableViewCell *)cell
{
    [cell setNeedsUpdateConstraints];
    [cell updateConstraintsIfNeeded];
}

- (void)configureEvaluateCell:(EvaluateCell *)cell forIndexPath:(NSIndexPath *)indexPath
{
    cell.scoreLabel.text = @"综合疗效评估";
    cell.scoreLabel.attributedText = [self configureLastLetter:[cell.scoreLabel.text stringByAppendingFormat:@" %@",self.dataArray[indexPath.row][0]]];
    cell.evaluateTextLabel.text = self.dataArray[indexPath.row][1];
    
    [self setupConstraintsWithCell:cell];

}

- (void)configureEffectCell:(EffectCell *)cell forIndexPath:(NSIndexPath *)indexPath
{
    
    cell.testCount.text = @"检测次数";
    cell.overproofCount.text = @"超标次数";
    cell.maximumValue.text = @"最高值";
    cell.minimumValue.text = @"最低值";
    cell.averageValue.text = @"平均值";
    
    
    cell.evaluateType.text = self.dataArray[indexPath.row-1][0];
    
    
    
    cell.maximumValue.attributedText = [self configureLastLetter:[cell.maximumValue.text stringByAppendingFormat:@" %@",self.dataArray[indexPath.row-1][3]]];
    cell.minimumValue.attributedText = [self configureLastLetter:[cell.minimumValue.text stringByAppendingFormat:@" %@",self.dataArray[indexPath.row-1][4]]];
    cell.averageValue.attributedText = [self configureLastLetter:[cell.averageValue.text stringByAppendingFormat:@" %@",self.dataArray[indexPath.row-1][5]]];
    
    if (indexPath.row == self.dataArray.count) {
        cell.testCount.text = @"";
        cell.overproofCount.text = @"";
        
    }else
    {
        cell.testCount.attributedText = [self configureLastLetter:[cell.testCount.text stringByAppendingFormat:@" %@",self.dataArray[indexPath.row-1][1]]];
        cell.overproofCount.attributedText = [self configureLastLetter:[cell.overproofCount.text stringByAppendingFormat:@" %@",self.dataArray[indexPath.row-1][2]]];
    }
    
    [self setupConstraintsWithCell:cell];

    
    
}

- (NSMutableAttributedString *)configureLastLetter:(NSString *)string
{
    
    NSRange range = [string rangeOfString:@" "];
    NSMutableAttributedString *aString = [[NSMutableAttributedString alloc] initWithString:string];
    [aString setAttributes:@{NSForegroundColorAttributeName: [UIColor orangeColor]} range:NSMakeRange(range.location+1, string.length-range.location-1) ];
    return aString;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self heightForBasicCellAtIndexPath:indexPath];
}

- (CGFloat)heightForBasicCellAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 0) {
        static EvaluateCell *evaluateCell = nil;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            evaluateCell = [self.tableView dequeueReusableCellWithIdentifier:@"EvaluateCell"];
        });
        [self configureEvaluateCell:evaluateCell forIndexPath:indexPath];
        return [self calculateHeightForConfiguredSizingCell:evaluateCell];
    }
    else if (indexPath.row == 1) {
        return 30;
    } else {
        static EffectCell *effectCell = nil;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            effectCell = [self.tableView dequeueReusableCellWithIdentifier:@"EffectCell"];
        });
        [self configureEffectCell:effectCell forIndexPath:indexPath];
        return [self calculateHeightForConfiguredSizingCell:effectCell];
        
    }
    
}

- (CGFloat)calculateHeightForConfiguredSizingCell:(UITableViewCell *)sizingCell
{
    sizingCell.bounds = CGRectMake(0.0f, 0.0, CGRectGetWidth(self.tableView.bounds), CGRectGetHeight(sizingCell.bounds));
    [sizingCell setNeedsLayout];
    [sizingCell layoutIfNeeded];
    
//    CGSize size = [sizingCell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
    CGFloat height = [sizingCell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height;
    height += 1;
    return height;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.row == 1) {
        hud = [[MBProgressHUD alloc] initWithView:self.view];
        [self.view addSubview:hud];
        hud.margin = 0;
        hud.customView = self.wrapperView;
        hud.mode = MBProgressHUDModeCustomView;
        [hud show:YES];
    }
}


#pragma mark - pickerViewDelegate

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return 4;
}

#pragma mark - pickerViewDataSource

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    return [[self.countDayDic allKeys] objectAtIndex:row] ;
}

- (IBAction)cancelAndConfirm:(id)sender
{
    UIButton *btn = (UIButton *)sender;
    switch (btn.tag) {
        case 1001:
        {
            break;
        }
        case 1002:
        {
            UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
            NSString *key = [[self.countDayDic allKeys] objectAtIndex:[self.pickerView selectedRowInComponent:0]];
            cell.detailTextLabel.text  = key;
            self.countDay = [self.countDayDic valueForKey:key];
            break;
        }
    }
    [hud hide:YES afterDelay:0.25];
}

@end
