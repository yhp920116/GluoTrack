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
@property (strong, nonatomic) NSArray *countDayArr;
@property (strong, nonatomic) NSString *countDay;

@property (strong, nonatomic) NSFetchedResultsController *fetchController;

@end

@implementation ControlEffectViewController

- (void)awakeFromNib
{
    self.countDay = @"7";
    self.dataArray = [NSMutableArray array];
    self.countDayDic = @{@"7":@"近7天",
                         @"14":@"近14天",
                         @"30":@"近30天",
                         @"60":@"近60天",
                         };
    self.countDayArr = @[@"7",@"14",@"30",@"60"];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self configureFetchController];
    self.tableView.estimatedRowHeight = UITableViewAutomaticDimension;
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];

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
                g3.name = NSLocalizedString(@"空腹血糖G3", nil);
                EffectList *g2 = [EffectList createEntityInContext:[CoreDataStack sharedCoreDataStack].context];
                [g2 updateCoreDataForData:[responseData objectForKey:@"g2"] withKeyPath:nil];
                g2.name = NSLocalizedString(@"餐后血糖G2", nil);
                EffectList *g1 = [EffectList createEntityInContext:[CoreDataStack sharedCoreDataStack].context];
                [g1 updateCoreDataForData:[responseData objectForKey:@"g1"] withKeyPath:nil];
                g1.name = NSLocalizedString(@"餐后血糖G1", nil);
                EffectList *hemoglobin = [EffectList createEntityInContext:[CoreDataStack sharedCoreDataStack].context];
                [hemoglobin updateCoreDataForData:[responseData objectForKey:@"hemoglobin"] withKeyPath:nil];
                hemoglobin.name = NSLocalizedString(@"糖化血糖蛋白", nil);
                
                [lists addObject:g3];
                [lists addObject:g1];
                [lists addObject:g2];
                [lists addObject:hemoglobin];
                
                controlEffect.effectList = lists;
                
                [[CoreDataStack sharedCoreDataStack] saveContext];
                
            }else{
                [NSString localizedMsgFromRet_code:ret_code withHUD:NO];
            }
        }
        [self.refreshView finishLoading];
    }];
}

#pragma mark - tableViewDelegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    NSInteger sections = 1;
    if (self.fetchController.sections.count > 0) {
        sections = self.fetchController.sections.count;
    }else sections = 0;
    return sections;

}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.fetchController.fetchedObjects.count > 0) {
        ControlEffect *controlEffect = self.fetchController.fetchedObjects[0];
        return controlEffect.effectList.count+2;
    }else{
        return 6;
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
        cell.textLabel.text = NSLocalizedString(@"选择周期",nil);
        cell.detailTextLabel.text = [self.countDayDic valueForKey:self.countDay];
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
    ControlEffect *controlEffect;
    if (self.fetchController.fetchedObjects.count > 0) {
        controlEffect = [self.fetchController objectAtIndexPath:indexPath];
    }
    
    
    cell.scoreLabel.text = NSLocalizedString(@"综合疗效评估",nil);
    if (controlEffect.conclusionScore) {
        cell.scoreLabel.attributedText = [self configureLastLetter:[cell.scoreLabel.text stringByAppendingFormat:@" %@分",controlEffect.conclusionScore]];
    }else{
        cell.scoreLabel.attributedText = [self configureLastLetter:[cell.scoreLabel.text stringByAppendingFormat:@" %@",@"--"]];
    }
    
    if ((!controlEffect.conclusionDesc && [controlEffect.conclusionDesc isEqualToString:@""]) || (!controlEffect.conclusion && ![controlEffect.conclusion isEqualToString:@""])) {
        cell.evaluateTextLabel.text = [NSString stringWithFormat:@"%@  %@",controlEffect.conclusion?controlEffect.conclusion:@"",controlEffect.conclusionDesc];
    }else{
        NSDictionary *attributes = @{NSForegroundColorAttributeName: [UIColor orangeColor]};
        NSAttributedString *aString = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"暂时无法获取控糖成效", nil) attributes:attributes];
        cell.evaluateTextLabel.attributedText = aString;
    }
    
    
    [self setupConstraintsWithCell:cell];

}

- (void)configureEffectCell:(EffectCell *)cell forIndexPath:(NSIndexPath *)indexPath
{
    ControlEffect *controlEffect;
    EffectList *effectList;
    if (self.fetchController.fetchedObjects.count > 0) {
        controlEffect = self.fetchController.fetchedObjects[0];
        effectList = [controlEffect.effectList objectAtIndex:indexPath.row-2];
    }
    
    
    cell.testCount.text = NSLocalizedString(@"检测次数",nil);
    cell.overproofCount.text = NSLocalizedString(@"超标次数",nil);
    cell.maximumValue.text = NSLocalizedString(@"最高值",nil);
    cell.minimumValue.text = NSLocalizedString(@"最低值",nil);
    cell.averageValue.text = NSLocalizedString(@"平均值",nil);
    
    
    cell.evaluateType.text = effectList.name;
    
    
    
    cell.maximumValue.attributedText = [self configureLastLetter:[cell.maximumValue.text stringByAppendingFormat:@" %@",effectList.max?effectList.max:@"--"]];
    cell.minimumValue.attributedText = [self configureLastLetter:[cell.minimumValue.text stringByAppendingFormat:@" %@",effectList.min?effectList.min:@"--"]];
    cell.averageValue.attributedText = [self configureLastLetter:[cell.averageValue.text stringByAppendingFormat:@" %@",effectList.avg?effectList.avg:@"--"]];
    cell.testCount.attributedText = [self configureLastLetter:[cell.testCount.text stringByAppendingFormat:@" %@",effectList.detectCount?effectList.detectCount:@"--"]];
    cell.overproofCount.attributedText = [self configureLastLetter:[cell.overproofCount.text stringByAppendingFormat:@" %@",effectList.overtopCount?effectList.overtopCount:@"--"]];
    
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
    
    return [self.countDayDic valueForKey:[self.countDayArr objectAtIndex:row]] ;
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
            self.countDay = [self.countDayArr objectAtIndex:[self.pickerView selectedRowInComponent:0]];

            cell.detailTextLabel.text  = [self.countDayDic valueForKey:self.countDay];
            
            [self.refreshView startLoadingAndExpand:YES animated:YES];
            break;
        }
    }
    [hud hide:YES afterDelay:0.25];
}

@end
