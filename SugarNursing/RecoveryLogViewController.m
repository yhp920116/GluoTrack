//
//  RecoveryLogViewController.m
//  SugarNursing
//
//  Created by Dan on 14-11-18.
//  Copyright (c) 2014年 Tisson. All rights reserved.
//

#import "RecoveryLogViewController.h"
#import "TimelineCell.h"
#import "NSString+Attribute.h"
#import <SSPullToRefresh.h>
#import <RMDateSelectionViewController.h>
#import "RecoveryLogHeaderView.h"
#import "RecoveryLogDetailViewController.h"
#import "TimelineTableView.h"
#import "UtilsMacro.h"

static NSString * const TimelineCellIdentifier = @"TimelineCell";

@interface RecoveryLogViewController ()<UITableViewDataSource,UITableViewDelegate,SSPullToRefreshViewDelegate,RMDateSelectionViewControllerDelegate,NSFetchedResultsControllerDelegate>{
    MBProgressHUD *hud;
}
@property (weak, nonatomic) IBOutlet TimelineTableView *tableView;
@property (strong, nonatomic) SSPullToRefreshView *refreshView;
@property (weak, nonatomic) IBOutlet UIView *popOverView;

@property (strong, nonatomic) NSFetchedResultsController *fetchController;
@property (strong, nonatomic) UserSetting *setting;
@property (strong, nonatomic) NSDate *selectedDate;
@property (strong, nonatomic) NSMutableArray *logTypeArray;

@property (weak, nonatomic) IBOutlet UIButton *detectCheckbox;
@property (weak, nonatomic) IBOutlet UIButton *drugCheckBox;
@property (weak, nonatomic) IBOutlet UIButton *dietCheckBox;
@property (weak, nonatomic) IBOutlet UIButton *exerciseCheckBox;

@end

@implementation RecoveryLogViewController

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"AddLog"]) {
        RecoveryLogDetailViewController *addVC = [segue destinationViewController];
        addVC.recoveryLogStatus = RecoveryLogStatusAdd;
    }
    
    if ([segue.identifier isEqualToString:@"EditLog"]) {
        RecoveryLogDetailViewController *editVC = [segue destinationViewController];
        RecordLog *recordLog = [self.fetchController objectAtIndexPath:[self.tableView indexPathForSelectedRow]];
        editVC.recordLog = recordLog;
        editVC.recoveryLogStatus = RecoveryLogStatusEdit;

        if ([recordLog.logType isEqualToString:@"detect"]) {
            editVC.recoveryLogType = RecoveryLogTypeDetect;
        }
        if ([recordLog.logType isEqualToString:@"drug"]) {
            editVC.recoveryLogType = RecoveryLogTypeDrug;
        }
        if ([recordLog.logType isEqualToString:@"diet"]) {
            editVC.recoveryLogType = RecoveryLogTypeDiet;
        }
        if ([recordLog.logType isEqualToString:@"exercise"]) {
            editVC.recoveryLogType = RecoveryLogTypeExercise;
        }
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.selectedDate = [NSDate date];
    [self configureUserSetting];
    [self configureTableView];
    [self configureFetchController:NO];
    [self.refreshView startLoadingAndExpand:YES animated:YES];
}

- (void)configureUserSetting
{
    self.logTypeArray = [@[] mutableCopy];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"userid.userId = %@ && userid.linkManId = %@",[NSString userID],[NSString linkmanID]];
    NSArray *userSetting = [UserSetting findAllWithPredicate:predicate inContext:[CoreDataStack sharedCoreDataStack].context];

    if (userSetting.count == 0) {
        self.setting = [UserSetting createEntityInContext:[CoreDataStack sharedCoreDataStack].context];
        UserID *userID = [UserID createEntityInContext:[CoreDataStack sharedCoreDataStack].context];
        userID.userId = [NSString userID];
        userID.linkManId = [NSString linkmanID];
        self.setting.userid = userID;
        [[CoreDataStack sharedCoreDataStack] saveContext];
    }else{
        self.setting = [UserSetting findAllWithPredicate:predicate inContext:[CoreDataStack sharedCoreDataStack].context][0];
    }
    
    if ([self.setting.detect boolValue] == YES) {
        [self.detectCheckbox setImage:[UIImage imageNamed:@"CheckboxY"] forState:UIControlStateNormal];
        [self.logTypeArray addObject:@"detect"];
    }else [self.detectCheckbox setImage:[UIImage imageNamed:@"CheckboxN"] forState:UIControlStateNormal];
    
    if ([self.setting.drug boolValue] == YES) {
        [self.drugCheckBox setImage:[UIImage imageNamed:@"CheckboxY"] forState:UIControlStateNormal];
        [self.logTypeArray addObject:@"drug"];
    }else [self.drugCheckBox setImage:[UIImage imageNamed:@"CheckboxN"] forState:UIControlStateNormal];
    
    if ([self.setting.diet boolValue] == YES) {
        [self.dietCheckBox setImage:[UIImage imageNamed:@"CheckboxY"] forState:UIControlStateNormal];
        [self.logTypeArray addObject:@"diet"];
    }else [self.dietCheckBox setImage:[UIImage imageNamed:@"CheckboxN"] forState:UIControlStateNormal];
    
    if ([self.setting.exercise boolValue] == YES) {
        [self.exerciseCheckBox setImage:[UIImage imageNamed:@"CheckboxY"] forState:UIControlStateNormal];
        [self.logTypeArray addObject:@"exercise"];
    }else [self.exerciseCheckBox setImage:[UIImage imageNamed:@"CheckboxN"] forState:UIControlStateNormal];
    
}

- (void)configureFetchController:(BOOL)refresh
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyyMMdd"];
    NSString *dateString = [dateFormatter stringFromDate:self.selectedDate];
    
    NSPredicate *predicate;
    if (refresh) {
        predicate = [NSPredicate predicateWithFormat:
                                  @"userid.userId = %@ && userid.linkManId = %@ && time beginswith[cd] %@ && logType in %@",
                                  [NSString userID],
                                  [NSString linkmanID],
                                  dateString,
                                  @[@"detect",@"exercise",@"drug",@"diet"]];
    }else{
        predicate = [NSPredicate predicateWithFormat:
                                @"userid.userId = %@ && userid.linkManId = %@ && time beginswith[cd] %@ && logType in %@",
                                [NSString userID],
                                [NSString linkmanID],
                                dateString,
                                self.logTypeArray];
    }
    
    self.fetchController = [RecordLog fetchAllGroupedBy:nil sortedBy:@"time" ascending:NO withPredicate:predicate delegate:self incontext:[CoreDataStack sharedCoreDataStack].context];
    
    [self.tableView reloadData];
    [self configureNoDataView];

}

- (void)configureTableView
{
    self.tableView.estimatedRowHeight = UITableViewAutomaticDimension;
    self.tableView.panGestureRecognizer.delaysTouchesBegan = YES;
    self.refreshView = [[SSPullToRefreshView alloc] initWithScrollView:self.tableView delegate:self];
    if ([self respondsToSelector:@selector(automaticallyAdjustsScrollViewInsets)]) {
        self.automaticallyAdjustsScrollViewInsets = NO;
    }
}

- (void)configureNoDataView
{
    if (self.fetchController.fetchedObjects.count > 0) {
        self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    }else{
        self.tableView.tableFooterView = [[NSBundle mainBundle] loadNibNamed:@"NoDataTips" owner:self options:nil][0];
    }
}

- (void)getRecoveryLog
{
    [self configureFetchController:YES];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyyMMdd"];
    NSString *queryDay = [dateFormatter stringFromDate:self.selectedDate];
    
    NSDictionary *parameters = @{@"method":@"queryCureLogTimeLine2",
                                 @"sign":@"sign",
                                 @"sessionId":[NSString sessionID],
                                 @"linkManId":[NSString linkmanID],
                                 @"queryDay":queryDay};
    [GCRequest userGetRecoveryRecordWithParameters:parameters withBlock:^(NSDictionary *responseData, NSError *error) {
        
        if (!error) {
            NSString *ret_code = [responseData objectForKey:@"ret_code"];
            if ([ret_code isEqualToString:@"0"]) {
                
                for (RecordLog *recordLog in self.fetchController.fetchedObjects) {
                    [recordLog deleteEntityInContext:[CoreDataStack sharedCoreDataStack].context];
                }
            
                NSArray *detectLogArr = [responseData objectForKey:@"detectLogList"];
                NSArray *dietLogArr = [responseData objectForKey:@"dietLogList"];
                NSArray *drugLogArr = [responseData objectForKey:@"drugLogList"];
                NSArray *exerciseLogArr = [responseData objectForKey:@"exerciseLogList"];
            
                
                for (NSDictionary *detectLogDic in detectLogArr) {
                
                    RecordLog *recordLog = [RecordLog createEntityInContext:[CoreDataStack sharedCoreDataStack].context];
                    [recordLog updateCoreDataForData:detectLogDic withKeyPath:nil];
                    
                    DetectLog *detect = [DetectLog createEntityInContext:[CoreDataStack sharedCoreDataStack].context];
                    NSMutableDictionary *detectDic = [[detectLogDic objectForKey:@"detectLog"] mutableCopy];
                    [detectDic feelingFormattingToUserForKey:@"selfSense"];
                    [detect updateCoreDataForData:detectDic withKeyPath:nil];
                    
                    UserID *userID = [UserID createEntityInContext:[CoreDataStack sharedCoreDataStack].context];
                    userID.userId = [NSString userID];
                    userID.linkManId = [NSString linkmanID];
                    
                    recordLog.detectLog = detect;
                    recordLog.userid = userID;
                }
                
                for (NSDictionary *dietLogDic in dietLogArr) {
                    RecordLog *recordLog = [RecordLog createEntityInContext:[CoreDataStack sharedCoreDataStack].context];
                    [recordLog updateCoreDataForData:dietLogDic withKeyPath:nil];
                    
                    UserID *userID = [UserID createEntityInContext:[CoreDataStack sharedCoreDataStack].context];
                    userID.userId = [NSString userID];
                    userID.linkManId = [NSString linkmanID];
                    
                    DietLog *diet = [DietLog createEntityInContext:[CoreDataStack sharedCoreDataStack].context];
                    NSMutableDictionary *dietDic = [[dietLogDic objectForKey:@"dietLog"] mutableCopy];
                    [dietDic eatPeriodFormattingToUserForKey:@"eatPeriod"];
                    [diet updateCoreDataForData:dietDic withKeyPath:nil];
                    
                    NSMutableOrderedSet *foodList = [[NSMutableOrderedSet alloc] initWithCapacity:10];
                    for (NSDictionary *foodDic in [dietDic objectForKey:@"foodList"]) {
                        
                        NSMutableDictionary *fooDic_ = [foodDic mutableCopy];
//                        [fooDic_ unitFormattingToUserForKey:@"unit"];
                        
                        Food *food = [Food createEntityInContext:[CoreDataStack sharedCoreDataStack].context];
                        [food updateCoreDataForData:fooDic_ withKeyPath:nil];
                        [foodList addObject:food];
                    }
                    
                    recordLog.userid = userID;
                    recordLog.dietLog = diet;
                    diet.foodList = foodList;

                }
                
                for (NSDictionary *drugLogDic in drugLogArr) {
                    RecordLog *recordLog = [RecordLog createEntityInContext:[CoreDataStack sharedCoreDataStack].context];
                    [recordLog updateCoreDataForData:drugLogDic withKeyPath:nil];
                    
                    UserID *userID = [UserID createEntityInContext:[CoreDataStack sharedCoreDataStack].context];
                    userID.userId = [NSString userID];
                    userID.linkManId = [NSString linkmanID];
                    
                    DrugLog *drug = [DrugLog createEntityInContext:[CoreDataStack sharedCoreDataStack].context];
                    [drug updateCoreDataForData:[drugLogDic objectForKey:@"drugLog"] withKeyPath:nil];
                    
                    NSMutableOrderedSet *medicineList = [[NSMutableOrderedSet alloc] initWithCapacity:10];
                    
                    for (NSDictionary *medicineDic in [[drugLogDic objectForKey:@"drugLog"] objectForKey:@"medicineList"]) {
                        
                        NSMutableDictionary *medicineDic_ = [medicineDic mutableCopy];
                        [medicineDic_ medicineUnitsFormattingToUserForKey:@"unit"];
                        [medicineDic_ medicineUsageFormattingToUserForKey:@"usage"];
                        
                        Medicine *medicine = [Medicine createEntityInContext:[CoreDataStack sharedCoreDataStack].context];
                        [medicine updateCoreDataForData:medicineDic_ withKeyPath:nil];
                        [medicineList addObject:medicine];
                    }
                    
                    recordLog.userid = userID;
                    drug.medicineList = medicineList;
                    recordLog.drugLog = drug;

                }
                
                for (NSDictionary *exerciseLogDic in exerciseLogArr) {
                    RecordLog *recordLog = [RecordLog createEntityInContext:[CoreDataStack sharedCoreDataStack].context];
                    [recordLog updateCoreDataForData:exerciseLogDic withKeyPath:nil];
                    
                    ExerciseLog *exercise = [ExerciseLog createEntityInContext:[CoreDataStack sharedCoreDataStack].context];
                    [exercise updateCoreDataForData:[exerciseLogDic objectForKey:@"exerciseLog"] withKeyPath:nil];
                    
                    UserID *userID = [UserID createEntityInContext:[CoreDataStack sharedCoreDataStack].context];
                    userID.userId = [NSString userID];
                    userID.linkManId = [NSString linkmanID];
                    
                    recordLog.exerciseLog = exercise;
                    recordLog.userid = userID;

                }
                [[CoreDataStack sharedCoreDataStack] saveContext];
                
            }else{
                [NSString localizedMsgFromRet_code:ret_code withHUD:NO];
            }
        }

        
        // 无论是请求成功或者失败，都要再重新fetch一次，以过滤用户对日期和选项的筛选
        
        [self configureFetchController:NO];
        [self.refreshView finishLoading];

    }];
}

#pragma mark - NSFectchedResultController


//- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
//{
//    [self.tableView beginUpdates];
//}
//
//- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath
//{
//    switch (type) {
//        case NSFetchedResultsChangeInsert:
//            [self.tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
//            break;
//        case NSFetchedResultsChangeDelete:
//            [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
//            break;
//        case NSFetchedResultsChangeMove:
//            [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
//            [self.tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
//            break;
//        case NSFetchedResultsChangeUpdate:
//        {
//            TimelineCell *cell = (TimelineCell *)[self.tableView cellForRowAtIndexPath:indexPath];
//            [self configureTimelineCell:cell atIndexPath:indexPath];
//            
//            break;
//        }
//        default:
//            break;
//    }
//    [self configureNoDataView];
//}
//
//- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
//{
//    [self.tableView endUpdates];
//}

#pragma mark - refreshViewDelegate

- (void)pullToRefreshViewDidStartLoading:(SSPullToRefreshView *)view
{
    [self getRecoveryLog];
}

- (void)pullToRefreshViewDidFinishLoading:(SSPullToRefreshView *)view
{
    // do whatever afther finsh loading
}

#pragma mark - TableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.fetchController.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.fetchController.sections[section] numberOfObjects];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 44;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    RecoveryLogHeaderView *headerView = [[RecoveryLogHeaderView alloc] init];
    [self configureHeaderSectionView:headerView inSection:section];
    return headerView;
}

- (void)configureHeaderSectionView:(RecoveryLogHeaderView *)headerView inSection:(NSInteger)section
{
    headerView.day = self.selectedDate;
    headerView.currentDay = YES;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self timelineCellAtIndexPath:indexPath];
}


- (TimelineCell *)timelineCellAtIndexPath:(NSIndexPath *)indexPath
{
    TimelineCell *cell = [self.tableView dequeueReusableCellWithIdentifier:TimelineCellIdentifier forIndexPath:indexPath];
    [self configureTimelineCell:cell atIndexPath:indexPath];
    return cell;
}

- (void)setupConstrainsWithTimelineCell:(TimelineCell *)cell
{
    [cell setNeedsUpdateConstraints];
    [cell updateConstraintsIfNeeded];
}

- (void)configureTimelineCell:(TimelineCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    RecordLog *recordLog = [self.fetchController objectAtIndexPath:indexPath];
    
    // Configure Time
    
    cell.timeLabel.text = [NSString formattingDateString:recordLog.time From:@"yyyyMMddHHmmss" to:@"HH:mm"];

    // Configure Icon
    cell.timelineImageView.image = [self configureImageForTimelineCell:recordLog.logType];
    
    // Configure Title
    NSString *key = recordLog.logType;
    cell.titleLabel.text = NSLocalizedString(key, nil);
    
    // Configure Detail content
    cell.detailLabel.text = [self configureDetailInfoForRecordLog:recordLog];
    
    
//    NSAttributedString *detailContentAttr = [[NSAttributedString alloc] initWithString:detailContent attributes:[NSString attributeCommonInit]];
//    cell.detailLabel.attributedText = detailContentAttr;
    
    [self setupConstrainsWithTimelineCell:cell];

    
}

- (UIImage *)configureImageForTimelineCell:(NSString *)type
{
    UIImage *iconImage = [UIImage imageNamed:[NSString stringWithFormat:@"%@",type]];
    return iconImage;
}

- (NSString *)configureDetailInfoForRecordLog:(RecordLog *)recordLog
{
    NSString *detailContent = @"";
    if ([recordLog.logType isEqualToString:@"detect"]) {
        DetectLog *detect = recordLog.detectLog;

        if (detect.glucose && ![detect.glucose isEqualToString:@""]) {
            detailContent = [NSString stringWithFormat:@"%@  %@mmol/L",NSLocalizedString(@"glucose", nil), detect.glucose];
        }
        if (detect.hemoglobinef && ![detect.hemoglobinef isEqualToString:@""]) {
            detailContent = [detailContent stringByAppendingFormat:@"\n%@  %@%%",NSLocalizedString(@"hemoglobin", nil), detect.hemoglobinef];
        }
        
        if ([detailContent hasPrefix:@"\n"]) {
            detailContent = [detailContent substringFromIndex:1];
        }
        
    }
    
    if ([recordLog.logType isEqualToString:@"diet"]) {
        DietLog *diet = recordLog.dietLog;
        NSMutableArray *foodArr = [NSMutableArray arrayWithCapacity:10];
        for (Food *food in diet.foodList) {
            NSString *aFood = [NSString stringWithFormat:@"%@  %@  %@%@  %@%@",food.sort,food.food,food.weight,food.unit,food.calorie,NSLocalizedString(@"calorie", nil)];
            [foodArr addObject:aFood];
        }
        detailContent = [foodArr componentsJoinedByString:@"\n"];
    }
    
    if ([recordLog.logType isEqualToString:@"drug"]) {
        DrugLog *drug = recordLog.drugLog;
        NSMutableArray *medicineArr = [NSMutableArray arrayWithCapacity:10];
        for (Medicine *medicine in drug.medicineList) {
            NSString *aMedicine = [NSString stringWithFormat:@"%@  %@  %@  %@%@",medicine.sort,medicine.usage,medicine.drug,medicine.dose,medicine.unit];
            [medicineArr addObject:aMedicine];
        }
        detailContent = [medicineArr componentsJoinedByString:@"\n"];
    }
    
    if ([recordLog.logType isEqualToString:@"exercise"]) {
        ExerciseLog *exercise = recordLog.exerciseLog;
        detailContent = [NSString stringWithFormat:@"%@  %@%@  %@%@",exercise.sportName,exercise.duration,NSLocalizedString(@"minutes", nil),exercise.calorie,NSLocalizedString(@"calorie", nil)];
    }
    
    return detailContent;
}

#pragma mark - TableViewDelegate


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self heightForBasicCellAtIndexPath:indexPath];
}

- (CGFloat)heightForBasicCellAtIndexPath:(NSIndexPath *)indexPath
{
    static TimelineCell *sizingCell = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sizingCell = [self.tableView dequeueReusableCellWithIdentifier:TimelineCellIdentifier];
    });
    [self configureTimelineCell:sizingCell atIndexPath:indexPath];
    return [self calculateHeightForConfiguredSizingCell:sizingCell];
}

- (CGFloat)calculateHeightForConfiguredSizingCell:(UITableViewCell *)sizingCell
{
    sizingCell.bounds = CGRectMake(0.0f, 0.0, CGRectGetWidth(self.tableView.bounds), CGRectGetHeight(sizingCell.bounds));
    [sizingCell setNeedsLayout];
    [sizingCell layoutIfNeeded];
    
    CGSize size = [sizingCell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
    return size.height;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        
        MBProgressHUD *aHud = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
        [self.navigationController.view addSubview:aHud];
        aHud.labelText = NSLocalizedString(@"Saving Data", nil);
        [aHud show:YES];
    
        RecordLog *deleteLog = [self.fetchController objectAtIndexPath:indexPath];
        
        if ([deleteLog.logType isEqualToString:@"detect"]) {
            
            NSDictionary *parameters = @{@"method":@"detectLogDelete",
                                         @"sign":@"sign",
                                         @"sessionId":[NSString sessionID],
                                         @"linkManId":[NSString linkmanID],
                                         @"detectId":deleteLog.id};
            [GCRequest userDeleteDetectLogWithParameters:parameters withBlock:^(NSDictionary *responseData, NSError *error) {
                aHud.mode = MBProgressHUDModeText;
                if (!error) {
                    NSString *ret_code = [responseData valueForKey:@"ret_code"];
                    if ([ret_code isEqualToString:@"0"]) {
                        [deleteLog deleteEntityInContext:[CoreDataStack sharedCoreDataStack].context];
                        aHud.labelText = NSLocalizedString(@"Data Updated", nil);
                    }else{
                        aHud.labelText = [NSString localizedMsgFromRet_code:ret_code withHUD:YES];
                    }
                }else{
                    aHud.labelText = NSLocalizedString(@"Server is busy", nil);
                }
                
                [aHud hide:YES afterDelay:HUD_TIME_DELAY];
            }];
        }
        
        if ([deleteLog.logType isEqualToString:@"drug"]) {
            
            NSDictionary *parameters = @{@"method":@"drugLogDelete",
                                         @"sign":@"sign",
                                         @"sessionId":[NSString sessionID],
                                         @"linkManId":[NSString linkmanID],
                                         @"medicineId":deleteLog.id};
            [GCRequest userDeleteDrugLogWithParameters:parameters withBlock:^(NSDictionary *responseData, NSError *error) {
                aHud.mode = MBProgressHUDModeText;
                if (!error) {
                    NSString *ret_code = [responseData valueForKey:@"ret_code"];
                    if ([ret_code isEqualToString:@"0"]) {
                        [deleteLog deleteEntityInContext:[CoreDataStack sharedCoreDataStack].context];
                        aHud.labelText = NSLocalizedString(@"Data Updated", nil);
                    }else{
                        aHud.labelText = [NSString localizedMsgFromRet_code:ret_code withHUD:YES];
                    }
                }else{
                    aHud.labelText = NSLocalizedString(@"Server is busy", nil);
                }
                [aHud hide:YES afterDelay:HUD_TIME_DELAY];

            }];
        }
        
        if ([deleteLog.logType isEqualToString:@"diet"]) {
            NSDictionary *parameters = @{@"method":@"dietLogDelete",
                                         @"sign":@"sign",
                                         @"sessionId":[NSString sessionID],
                                         @"linkManId":[NSString linkmanID],
                                         @"eatId":deleteLog.id};
            [GCRequest userDeleteDietLogWithParameters:parameters withBlock:^(NSDictionary *responseData, NSError *error) {
                aHud.mode = MBProgressHUDModeText;
                if (!error) {
                    NSString *ret_code = [responseData valueForKey:@"ret_code"];
                    if ([ret_code isEqualToString:@"0"]) {
                        [deleteLog deleteEntityInContext:[CoreDataStack sharedCoreDataStack].context];
                        aHud.labelText = NSLocalizedString(@"Data Updated", nil);
                    }else{
                        aHud.labelText = [NSString localizedMsgFromRet_code:ret_code withHUD:YES];
                    }
                }else{
                    aHud.labelText = NSLocalizedString(@"Server is busy", nil);
                }
                [aHud hide:YES afterDelay:HUD_TIME_DELAY];

            }];
        }
        
        if ([deleteLog.logType isEqualToString:@"exercise"]) {
            NSDictionary *parameters = @{@"method":@"exerciseLogDelete",
                                         @"sign":@"sign",
                                         @"sessionId":[NSString sessionID],
                                         @"linkManId":[NSString linkmanID],
                                         @"sportId":deleteLog.id};
            [GCRequest userDeleteExerciseLogWithParameters:parameters withBlock:^(NSDictionary *responseData, NSError *error) {
                aHud.mode = MBProgressHUDModeText;
                if (!error) {
                    NSString *ret_code = [responseData valueForKey:@"ret_code"];
                    if ([ret_code isEqualToString:@"0"]) {
                        [deleteLog deleteEntityInContext:[CoreDataStack sharedCoreDataStack].context];
                        aHud.labelText = NSLocalizedString(@"Data Updated", nil);
                    }else{
                        aHud.labelText = [NSString localizedMsgFromRet_code:ret_code withHUD:YES];
                    }
                }else{
                    aHud.labelText = NSLocalizedString(@"Server is busy", nil);
                }
                [aHud hide:YES afterDelay:HUD_TIME_DELAY];

            }];
        }
    }
}


#pragma mark - userAction

- (IBAction)topButtonTapped:(id)sender
{
    UIButton *btn = (UIButton *)sender;
    if (btn.tag == 0) {
        [self.tableView reloadData];
    } else if (btn.tag == 1) {
        
        [RMDateSelectionViewController setLocalizedTitleForCancelButton:NSLocalizedString(@"Cancel", nil)];
        [RMDateSelectionViewController setLocalizedTitleForNowButton:NSLocalizedString(@"30 days recently", nil)];
        [RMDateSelectionViewController setLocalizedTitleForSelectButton:NSLocalizedString(@"Select By Day", nil)];
        
        RMDateSelectionViewController *dateSelectionVC = [RMDateSelectionViewController dateSelectionController];
        dateSelectionVC.delegate = self;
        dateSelectionVC.hideNowButton = YES;
        dateSelectionVC.disableBlurEffects = NO;
        dateSelectionVC.disableBouncingWhenShowing = NO;
        dateSelectionVC.disableMotionEffects = NO;
        dateSelectionVC.blurEffectStyle = UIBlurEffectStyleExtraLight;
        dateSelectionVC.datePicker.datePickerMode = UIDatePickerModeDate;
        [dateSelectionVC show];
        
    } else if (btn.tag == 2) {
        hud = [[MBProgressHUD alloc] initWithView:self.view];
        [self.view addSubview:hud];
        hud.margin = 0;
        hud.customView = self.popOverView;
        hud.mode = MBProgressHUDModeCustomView;
        [hud show:YES];
    }
}

- (IBAction)optionTapped:(id)sender
{
    UIButton *btn = (UIButton *)sender;
    switch (btn.tag) {
        case 100:
        {
            // Cancel
            break;
        }
        case 101:
        {
            [self configureFetchController:NO];
            break;
        }
        default:
            break;
    }

    [hud hide:YES afterDelay:0.2];
}

- (IBAction)checkboxSelected:(id)sender
{
    UIButton *selectBtn = (UIButton *)sender;

    if ([selectBtn.currentImage isEqual:[UIImage imageNamed:@"CheckboxN"]]) {
        [selectBtn setImage:[UIImage imageNamed:@"CheckboxY"] forState:UIControlStateNormal];
        
        NSString *type ;
        switch (selectBtn.tag) {
            case 1:
            {
                type = @"detect";
                self.setting.detect = @1;
                break;
            }
            case 2:
            {
                type = @"drug";
                self.setting.drug = @1;
                break;
            }
            case 3:
            {
                type = @"diet";
                self.setting.diet = @1;
                break;
            }
            case 4:
            {
                type = @"exercise";
                self.setting.exercise = @1;
                break;
            }
            default:
                break;
        }
        
        if (![self.logTypeArray containsObject:type]) {
            [self.logTypeArray addObject:type];
        }
        
    } else {
        [selectBtn setImage:[UIImage imageNamed:@"CheckboxN"] forState:UIControlStateNormal];
        
        NSString *type ;
        switch (selectBtn.tag) {
            case 1:
            {
                type = @"detect";
                self.setting.detect = @0;
                break;
            }
            case 2:
            {
                type = @"drug";
                self.setting.drug = @0;
                break;
            }
            case 3:
            {
                type = @"diet";
                self.setting.diet = @0;
                break;
            }
            case 4:
            {
                type = @"exercise";
                self.setting.exercise = @0;
                break;
            }
            default:
                break;
        }
        
        if ([self.logTypeArray containsObject:type]) {
            [self.logTypeArray removeObject:type];
        }
    }
    
    [[CoreDataStack sharedCoreDataStack] saveContext];
    
}

#pragma mark - RMDateSelectionViewControllerDelegate

- (void)dateSelectionViewController:(RMDateSelectionViewController *)vc didSelectDate:(NSDate *)aDate
{
    self.selectedDate = aDate;
    [self.refreshView startLoadingAndExpand:YES animated:YES];
}

- (void)dateSelectionViewControllerNowButtonPressed:(RMDateSelectionViewController *)vc
{
    [vc dismiss];
}

#pragma mark - unwindSegue

- (IBAction)back:(UIStoryboardSegue *)segue
{
    
}


@end
