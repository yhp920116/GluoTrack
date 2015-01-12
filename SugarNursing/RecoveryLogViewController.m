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
@property (strong, nonatomic) NSDate *selectedDate;
@property (strong, nonatomic) NSMutableArray *logTypeArray;

@end

@implementation RecoveryLogViewController

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"AddLog"]) {
        RecoveryLogDetailViewController *addVC = [segue destinationViewController];
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
    self.logTypeArray = [@[@"detect",@"exercise",@"drug",@"diet"] mutableCopy];
    [self configureFetchController];
    self.tableView.estimatedRowHeight = UITableViewAutomaticDimension;
    self.refreshView = [[SSPullToRefreshView alloc] initWithScrollView:self.tableView delegate:self];
    if ([self respondsToSelector:@selector(automaticallyAdjustsScrollViewInsets)]) {
        self.automaticallyAdjustsScrollViewInsets = NO;
    }
    
    [self.refreshView startLoadingAndExpand:YES animated:YES];
}

- (void)configureFetchController
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyyMMdd"];
    NSString *dateString = [dateFormatter stringFromDate:self.selectedDate];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"userid.userId = %@ && userid.linkManId = %@ && time beginswith[cd] %@ && logType in %@",[NSString userID],[NSString linkmanID],dateString,self.logTypeArray];
    self.fetchController = [RecordLog fetchAllGroupedBy:nil sortedBy:@"time" ascending:NO withPredicate:predicate delegate:self incontext:[CoreDataStack sharedCoreDataStack].context];
}

- (void)getRecoveryLog
{
    hud = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
    [self.navigationController.view addSubview:hud];
    hud.mode = MBProgressHUDModeText;
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyyMMdd"];
    NSString *queryDay = [dateFormatter stringFromDate:self.selectedDate];
    
    NSDictionary *parameters = @{@"method":@"queryCureLogTimeLine",
                                 @"sign":@"sign",
                                 @"sessionId":[NSString sessionID],
                                 @"linkManId":[NSString linkmanID],
                                 @"queryDay":queryDay};
    [GCRequest userGetRecoveryRecordWithParameters:parameters withBlock:^(NSDictionary *responseData, NSError *error) {
        
        if (!error) {
            if ([[responseData valueForKey:@"ret_code"] isEqualToString:@"0"]) {
                
                for (RecordLog *recordLog in self.fetchController.fetchedObjects) {
                    [recordLog deleteEntityInContext:[CoreDataStack sharedCoreDataStack].context];
                }
            
                NSArray *recordLogArray;
                if ([[responseData objectForKey:@"cureLogList"] isKindOfClass:[NSArray class]]) {
                    recordLogArray = [responseData objectForKey:@"cureLogList"];
                }else{
                    recordLogArray = @[];
                }
                
                for (NSDictionary *recordLogDic in recordLogArray) {
                    
                    NSMutableDictionary *recordLogDic_ = [recordLogDic mutableCopy];
                    NSMutableOrderedSet *evenList = [[NSMutableOrderedSet alloc] initWithCapacity:5];
                    
                    RecordLog *recordLog = [RecordLog createEntityInContext:[CoreDataStack sharedCoreDataStack].context];
                    [recordLog updateCoreDataForData:recordLogDic_ withKeyPath:nil];
                    
                    UserID *userID = [UserID createEntityInContext:[CoreDataStack sharedCoreDataStack].context];
                    userID.userId = [NSString userID];
                    userID.linkManId = [NSString linkmanID];
                    recordLog.userid = userID;
                    
                    for (NSDictionary *logListDic in [recordLogDic_ objectForKey:@"eventList"]) {
                         RecordLogList *recordLogList = [RecordLogList createEntityInContext:[CoreDataStack sharedCoreDataStack].context];
                        [recordLogList updateCoreDataForData:logListDic withKeyPath:nil];
                        [evenList addObject:recordLogList];
                    }
                    
                    recordLog.eventList = evenList;
                }
                
                [[CoreDataStack sharedCoreDataStack] saveContext];
                
                hud.labelText = NSLocalizedString(@"Data Updated", nil);
            }else{
                hud.labelText = [responseData valueForKey:@"ret_msg"];
            }
            
        }else{
            hud.labelText = [error localizedDescription];
        }
        
        [hud show:YES];
        [hud hide:YES afterDelay:HUD_TIME_DELAY];
        
        [self.refreshView finishLoading];
        
    }];
}

#pragma mark - NSFectchedResultController

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView reloadData];
}

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
    NSMutableArray *detailArray = [[NSMutableArray alloc] initWithCapacity:10];
    for (RecordLogList *logList in recordLog.eventList) {
        NSString *key = logList.eventObject;
        NSString *aLog = [NSString stringWithFormat:@"%@  %@%@",NSLocalizedString(key, nil),logList.eventValue,logList.eventUnit];
        [detailArray addObject:aLog];
    }
    NSString *detailContent = [detailArray componentsJoinedByString:@"\n"];
    detailContent = [detailContent stringByReplacingOccurrencesOfString:@"  " withString:@"  "];
    cell.detailLabel.text = detailContent;
    
//    NSAttributedString *detailContentAttr = [[NSAttributedString alloc] initWithString:detailContent attributes:[NSString attributeCommonInit]];
//    cell.detailLabel.attributedText = detailContentAttr;
    
    [self setupConstrainsWithTimelineCell:cell];

    
}

- (UIImage *)configureImageForTimelineCell:(NSString *)type
{
    UIImage *iconImage = [UIImage imageNamed:[NSString stringWithFormat:@"%@",type]];
    return iconImage;
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
        dateSelectionVC.disableBlurEffects = NO;
        dateSelectionVC.disableBouncingWhenShowing = NO;
        dateSelectionVC.disableMotionEffects = NO;
        dateSelectionVC.blurEffectStyle = UIBlurEffectStyleExtraLight;
        dateSelectionVC.datePicker.datePickerMode = UIDatePickerModeDate;
        [dateSelectionVC show];
        
    } else if (btn.tag == 2) {
        hud = [[MBProgressHUD alloc] initWithView:self.view];
        [self.view addSubview:hud];
        hud.cornerRadius = 0;
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
            [self configureFetchController];
            [self.tableView reloadData];
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
    NSString *type ;
    switch (selectBtn.tag) {
        case 1:
        {
            type = @"detect";
            break;
        }
        case 2:
        {
            type = @"drug";
            break;
        }
        case 3:
        {
            type = @"diet";
            break;
        }
        case 4:
        {
            type = @"exercise";
            break;
        }
        default:
            break;
    }
    if ([selectBtn.currentImage isEqual:[UIImage imageNamed:@"CheckboxN"]]) {
        [selectBtn setImage:[UIImage imageNamed:@"CheckboxY"] forState:UIControlStateNormal];
        
        if (![self.logTypeArray containsObject:type]) {
            [self.logTypeArray addObject:type];
        }
        
    } else {
        [selectBtn setImage:[UIImage imageNamed:@"CheckboxN"] forState:UIControlStateNormal];
        
        if ([self.logTypeArray containsObject:type]) {
            [self.logTypeArray removeObject:type];
        }
    }
    
    
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
