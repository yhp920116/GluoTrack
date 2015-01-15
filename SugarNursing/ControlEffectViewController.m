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


@interface ControlEffectViewController ()<UITableViewDataSource, UITableViewDelegate,UIPickerViewDataSource,UIPickerViewDelegate, SSPullToRefreshViewDelegate, NSFetchedResultsControllerDelegate>{
    MBProgressHUD *hud;
}


@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) IBOutlet UIPickerView *pickerView;
@property (strong, nonatomic) IBOutlet UIView *wrapperView;
@property (strong, nonatomic) SSPullToRefreshView *refreshView;

@property (strong, nonatomic) NSMutableArray *dataArray;
@property (strong, nonatomic) NSDictionary *countDayDic;
@property (strong, nonatomic) NSString *countDay;

@property (strong, nonatomic) NSFetchedResultsController *fetchController;

@end

@implementation ControlEffectViewController

- (void)awakeFromNib
{
    self.countDay = @"7";
    self.dataArray = [NSMutableArray array];
    self.countDayDic = @{@"近3天":@"3",
                         @"近7天":@"7",
                         @"近2周":@"14",
                         @"近1个月":@"30",
                         };
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self configureFetchController];
    [self configureNoDataView];
    self.tableView.estimatedRowHeight = UITableViewAutomaticDimension;
}

- (void)viewDidLayoutSubviews
{
    if (self.refreshView == nil) {
        self.refreshView = [[SSPullToRefreshView alloc] initWithScrollView:self.tableView delegate:self];
        [self.refreshView startLoadingAndExpand:YES animated:YES];
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self configureNoDataView];
    [self.tableView reloadData];
}


- (void)configureFetchController
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"userid.userId = %@ && userid.linkManId = %@",[NSString userID],[NSString linkmanID]];
    self.fetchController = [ControlEffect fetchAllGroupedBy:nil sortedBy:@"userid.userId" ascending:YES withPredicate:predicate delegate:self incontext:[CoreDataStack sharedCoreDataStack].context];
}

#pragma mark - SSPUllToRefreshViewDelegate
- (void)pullToRefreshViewDidStartLoading:(SSPullToRefreshView *)view
{
    [self getControlEffectData];
}

- (void)getControlEffectData
{
    hud = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
    [self.navigationController.view addSubview:hud];
    hud.mode = MBProgressHUDModeText;
    
    NSDictionary *parameters = @{@"method":@"queryConclusion",
                                 @"sign":@"sign",
                                 @"sessionId":[NSString sessionID],
                                 @"linkManId":[NSString linkmanID],
                                 @"countDay":self.countDay};
    [GCRequest userGetControlEffectWithParameters:parameters withBlock:^(NSDictionary *responseData, NSError *error) {
        
        if (!error) {
            NSString *ret_code = [responseData valueForKey:@"ret_code"];
            if ([ret_code isEqualToString:@"0"]) {
                
                for (ControlEffect *controlEffect in self.fetchController.fetchedObjects) {
                    [controlEffect deleteEntityInContext:[CoreDataStack sharedCoreDataStack].context];
                }
                
                ControlEffect *controlEffect = [ControlEffect createEntityInContext:[CoreDataStack sharedCoreDataStack].context];
                UserID *userID = [UserID createEntityInContext:[CoreDataStack sharedCoreDataStack].context];
                userID.userId = [NSString userID];
                userID.linkManId = [NSString linkmanID];
                controlEffect.userid = userID;
                
                [controlEffect updateCoreDataForData:responseData withKeyPath:nil];
                
                NSMutableOrderedSet *lists = [[NSMutableOrderedSet alloc] initWithCapacity:10];
                
                EffectList *g3 = [EffectList createEntityInContext:[CoreDataStack sharedCoreDataStack].context];
                [g3 updateCoreDataForData:[responseData objectForKey:@"g3"] withKeyPath:nil];
                g3.name = @"空腹血糖G3";
                EffectList *g2 = [EffectList createEntityInContext:[CoreDataStack sharedCoreDataStack].context];
                [g2 updateCoreDataForData:[responseData objectForKey:@"g2"] withKeyPath:nil];
                g2.name = @"餐后血糖G2";
                EffectList *g1 = [EffectList createEntityInContext:[CoreDataStack sharedCoreDataStack].context];
                [g1 updateCoreDataForData:[responseData objectForKey:@"g1"] withKeyPath:nil];
                g1.name = @"餐后血糖G1";
                EffectList *hemoglobin = [EffectList createEntityInContext:[CoreDataStack sharedCoreDataStack].context];
                [hemoglobin updateCoreDataForData:[responseData objectForKey:@"hemoglobin"] withKeyPath:nil];
                hemoglobin.name = @"糖化血糖蛋白";
                
                [lists addObject:g3];
                [lists addObject:g2];
                [lists addObject:g1];
                [lists addObject:hemoglobin];
                
                controlEffect.effectList = lists;
                
                [[CoreDataStack sharedCoreDataStack] saveContext];
                
                hud.labelText = NSLocalizedString(@"Data Updated", nil);
            }else{
                hud.labelText = [NSString localizedMsgFromRet_code:ret_code];
            }
        }else{
            hud.labelText = [error localizedDescription];
            
        }
        [hud show:YES];
        [hud hide:YES afterDelay:HUD_TIME_DELAY];
        [self.refreshView finishLoading];
    }];
}

- (void)configureNoDataView
{
    if (self.fetchController.fetchedObjects.count > 0) {
        self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    }else{
        self.tableView.tableFooterView = [[NSBundle mainBundle] loadNibNamed:@"NoDataTips" owner:self options:nil][0];
    }
}

#pragma mark - tableViewDelegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.fetchController.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.fetchController.fetchedObjects.count > 0) {
        ControlEffect *controlEffect = self.fetchController.fetchedObjects[0];
        return controlEffect.effectList.count+2;
    }else{
        return 0;
    }
    
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
    ControlEffect *controlEffect = [self.fetchController objectAtIndexPath:indexPath];
    
    cell.scoreLabel.text = @"综合疗效评估";
    cell.scoreLabel.attributedText = [self configureLastLetter:[cell.scoreLabel.text stringByAppendingFormat:@" %@分",controlEffect.conclusionScore]];
    cell.evaluateTextLabel.text = [NSString stringWithFormat:@"%@  %@",controlEffect.conclusion,controlEffect.conclusionDesc];
    
    [self setupConstraintsWithCell:cell];

}

- (void)configureEffectCell:(EffectCell *)cell forIndexPath:(NSIndexPath *)indexPath
{
    ControlEffect *controlEffect = self.fetchController.fetchedObjects[0];
    EffectList *effectList = [controlEffect.effectList objectAtIndex:indexPath.row-2];
    
    cell.testCount.text = @"检测次数";
    cell.overproofCount.text = @"超标次数";
    cell.maximumValue.text = @"最高值";
    cell.minimumValue.text = @"最低值";
    cell.averageValue.text = @"平均值";
    
    
    cell.evaluateType.text = effectList.name;
    
    
    
    cell.maximumValue.attributedText = [self configureLastLetter:[cell.maximumValue.text stringByAppendingFormat:@" %@",effectList.max]];
    cell.minimumValue.attributedText = [self configureLastLetter:[cell.minimumValue.text stringByAppendingFormat:@" %@",effectList.min]];
    cell.averageValue.attributedText = [self configureLastLetter:[cell.averageValue.text stringByAppendingFormat:@" %@",effectList.avg]];
    cell.testCount.attributedText = [self configureLastLetter:[cell.testCount.text stringByAppendingFormat:@" %@",effectList.detectCount]];
    cell.overproofCount.attributedText = [self configureLastLetter:[cell.overproofCount.text stringByAppendingFormat:@" %@",effectList.overtopCount]];
    
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
            
            [self.refreshView startLoadingAndExpand:YES animated:YES];
            break;
        }
    }
    [hud hide:YES afterDelay:0.25];
}

@end
