//
//  TestTrackerViewController.m
//  SugarNursing
//
//  Created by Dan on 14-11-10.
//  Copyright (c) 2014年 Tisson. All rights reserved.
//

#import "TestTrackerViewController.h"
#import "UtilsMacro.h"
#import "DetectDataCell.h"

typedef NS_ENUM(NSInteger, GCType) {
    GCTypeTable = 0,
    GCTypeLine
};

typedef NS_ENUM(NSInteger, GCSearchMode) {
    GCSearchModeByDay = 0,
    GCSearchModeByMonth
};

typedef NS_ENUM(NSInteger, GCLineType) {
    GCLineTypeGlucose = 0,
    GCLineTypeHemo
};

@interface TestTrackerViewController ()<MBProgressHUDDelegate, NSFetchedResultsControllerDelegate, RMDateSelectionViewControllerDelegate>{
    MBProgressHUD *hud;
}

@property (strong, nonatomic) NSFetchedResultsController *GfetchController;
@property (strong, nonatomic) NSFetchedResultsController *HfetchController;
@property (assign) GCLineType lineType;
@property (assign) GCSearchMode searchMode;
@property (assign) GCType viewType;
@property (strong, nonatomic) NSDate *selectedDate;
@property (weak, nonatomic) IBOutlet UILabel *unitLabel;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;

@end

@implementation TestTrackerViewController



- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // lineType
    self.lineType = GCLineTypeGlucose;
    self.viewType = GCTypeLine;
    self.searchMode = GCSearchModeByDay;
    self.unitLabel.text = @"mmol/L";
    self.selectedDate = [NSDate date];
    self.dateLabel.text = [NSString formattingDate:self.selectedDate to:@"yyyy-MM-dd"];
    
    [self setBarRightItems];
    [self.tabBar setSelectedItem:[self.tabBar items][0]];
    if ([self respondsToSelector:@selector(automaticallyAdjustsScrollViewInsets)]) {
        self.automaticallyAdjustsScrollViewInsets = NO;
    }
    
    [self configureGraph];
    [self configureTableView];
    [self configureGraphAndTableView];
    [self getDetectionData];
}

- (void)configureGraphAndTableView
{
    switch (self.viewType) {
        case GCTypeLine:
            self.trackerChart.hidden = NO;
            self.tableView.hidden = YES;
            break;
        case GCTypeTable:
            self.trackerChart.hidden = YES;
            self.tableView.hidden = NO;
    }
}

#pragma mark - FetchController Delegate

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self.trackerChart reloadGraph];
}

- (void)configureFetchController
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    BOOL timeAscending;
    
    switch (self.searchMode) {
        case GCSearchModeByDay:
        {
            [dateFormatter setDateFormat:@"yyyyMMdd"];
            timeAscending = YES;
            break;
        }
        case GCSearchModeByMonth:
        {
            [dateFormatter setDateFormat:@"yyyyMM"];
            timeAscending = NO;
            break;
        }
        default:
            break;
    }

    NSString *dateString = [dateFormatter stringFromDate:self.selectedDate];
    
    NSPredicate *Gpredicate = [NSPredicate predicateWithFormat:@"logType = %@ && userid.userId = %@ && userid.linkManId = %@ && time beginswith[cd] %@ && detectLog.glucose != %@ && detectLog.glucose != %@" ,@"detect",[NSString userID],[NSString linkmanID],dateString,@"",nil];
    
    self.GfetchController = [RecordLog fetchAllGroupedBy:nil sortedBy:@"time" ascending:timeAscending withPredicate:Gpredicate delegate:self incontext:[CoreDataStack sharedCoreDataStack].context];
    
    NSPredicate *Hpredicate = [NSPredicate predicateWithFormat:@"logType = %@ && userid.userId = %@ && userid.linkManId = %@ && time beginswith[cd] %@ && detectLog.hemoglobinef != %@ && detectLog.hemoglobinef != %@" ,@"detect",[NSString userID],[NSString linkmanID],dateString,@"",nil];
    
    self.HfetchController = [RecordLog fetchAllGroupedBy:nil sortedBy:@"time" ascending:timeAscending withPredicate:Hpredicate delegate:self incontext:[CoreDataStack sharedCoreDataStack].context];
    
    [self.tableView reloadData];
    [self.trackerChart reloadGraph];
}

- (void)getDetectionData
{
    [self configureFetchController];
    
    NSString *lineType;
    switch (self.lineType) {
        case GCLineTypeGlucose:
            lineType = @"1";
            break;
        case GCLineTypeHemo:
            lineType= @"2";
            break;
    }
    
    NSMutableDictionary *parameters = [@{@"method":@"queryDetectDetailLine2",
                                         @"sign":@"sign",
                                         @"sessionId":[NSString sessionID],
                                         @"linkManId":[NSString linkmanID],
                                         } mutableCopy];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    
    switch (self.searchMode) {
        case GCSearchModeByDay:
        {
            [dateFormatter setDateFormat:@"yyyy-MM-dd"];
            NSString *dateString = [dateFormatter stringFromDate:self.selectedDate];
            [parameters setValue:dateString forKey:@"queryDay"];
            break;
        }
        case GCSearchModeByMonth:
        {
            [parameters setValue:@"30" forKey:@"countDay"];
            break;
        }
        default:
            break;
    }

    [GCRequest userGetDetectionDataWithParameters:parameters withBlock:^(NSDictionary *responseData, NSError *error) {
        
        if (!error) {
            NSString *ret_code = [responseData objectForKey:@"ret_code"];
            if ([ret_code isEqualToString:@"0"]) {
                
                // 清除缓存
                for (RecordLog *recordLog in self.GfetchController.fetchedObjects) {
                    [recordLog deleteEntityInContext:[CoreDataStack sharedCoreDataStack].context];
                }
                for (RecordLog *recordLog in self.HfetchController.fetchedObjects) {
                    [recordLog deleteEntityInContext:[CoreDataStack sharedCoreDataStack].context];
                }
                
                NSArray *detectLogArr = [responseData objectForKey:@"detectLogList"];
                
                for (NSDictionary *detectLogDic in detectLogArr) {
                    
                    RecordLog *recordLog = [RecordLog createEntityInContext:[CoreDataStack sharedCoreDataStack].context];
                    [recordLog updateCoreDataForData:detectLogDic withKeyPath:nil];
                    
                    DetectLog *detect = [DetectLog createEntityInContext:[CoreDataStack sharedCoreDataStack].context];
                    [detect updateCoreDataForData:[detectLogDic objectForKey:@"detectLog"] withKeyPath:nil];
                    
                    UserID *userID = [UserID createEntityInContext:[CoreDataStack sharedCoreDataStack].context];
                    userID.userId = [NSString userID];
                    userID.linkManId = [NSString linkmanID];
                    
                    recordLog.detectLog = detect;
                    recordLog.userid = userID;
                }
                
                [[CoreDataStack sharedCoreDataStack] saveContext];
            }else{
                [NSString localizedMsgFromRet_code:ret_code withHUD:NO];
            }
        }
        
    }];
   
}

#pragma mark - Configuration

- (void )setBarRightItems
{
    UIButton *shareBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    shareBtn.frame = CGRectMake(0, 0, 26, 26);
    shareBtn.tag = 11;
    [shareBtn setImage:[UIImage imageNamed:@"table.png"] forState:UIControlStateNormal];
    [shareBtn addTarget:self action:@selector(rightBarButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *share = [[UIBarButtonItem alloc] initWithCustomView:shareBtn];
    
    UIButton *calenderBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    calenderBtn.frame = CGRectMake(0, 0, 26, 26);
    calenderBtn.tag = 12;
    [calenderBtn setImage:[UIImage imageNamed:@"date.png"] forState:UIControlStateNormal];
    [calenderBtn addTarget:self action:@selector(rightBarButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *calender = [[UIBarButtonItem alloc] initWithCustomView:calenderBtn];
    
    self.navigationItem.rightBarButtonItems = @[calender,share];
}

- (void)rightBarButtonAction:(id)sender
{
    UIButton *btn = (UIButton *)sender;
    switch (btn.tag) {
        case 11:
        {
            if ([btn.currentImage isEqual:[UIImage imageNamed:@"line.png"]]) {
                [btn setImage:[UIImage imageNamed:@"table.png"] forState:UIControlStateNormal];
                self.viewType = GCTypeLine;
            }else{
                [btn setImage:[UIImage imageNamed:@"line.png"] forState:UIControlStateNormal];
                self.viewType = GCTypeTable;
            }
            [self configureGraphAndTableView];
            [self configureFetchController];
            break;
        }
        case 12:
        {
            [self showDateSelectionVC];
            break;
        }
        default:
            break;
    }

}

- (void)configureGraph
{
    self.trackerChart.labelFont = [UIFont systemFontOfSize:10.];
    self.trackerChart.colorTop = [UIColor clearColor];
    self.trackerChart.colorBottom = [UIColor colorWithRed:1 green:1 blue:1 alpha:0.1];
    self.trackerChart.colorXaxisLabel = [UIColor darkGrayColor];
    self.trackerChart.colorYaxisLabel = [UIColor darkGrayColor];
    self.trackerChart.colorLine = [UIColor lightGrayColor];
    self.trackerChart.colorPoint = [UIColor orangeColor];
    self.trackerChart.colorBackgroundPopUplabel = [UIColor clearColor];
    self.trackerChart.widthLine = 1.0;
    self.trackerChart.enableTouchReport = YES;
    self.trackerChart.enablePopUpReport = YES;
    self.trackerChart.enableBezierCurve = NO;
    self.trackerChart.enableYAxisLabel = YES;
    self.trackerChart.enableXAxisLabel = YES;
    self.trackerChart.autoScaleYAxis = YES;
    self.trackerChart.alwaysDisplayDots = YES;
    self.trackerChart.sizePoint = 10;
//    self.trackerChart.alwaysDisplayPopUpLabels = YES;
    self.trackerChart.enableReferenceXAxisLines = YES;
    self.trackerChart.enableReferenceYAxisLines = YES;
    self.trackerChart.enableReferenceAxisFrame = YES;
    self.trackerChart.animationGraphStyle = BEMLineAnimationDraw;
}

- (void)configureTableView
{
    
}


#pragma mark - trackerChart Data Source

- (NSInteger)numberOfPointsInLineGraph:(BEMSimpleLineGraphView *)graph
{
    NSInteger count;
    switch (self.lineType) {
        case GCLineTypeGlucose:
            count = self.GfetchController.fetchedObjects.count;
            break;
        case GCLineTypeHemo:
            count = self.HfetchController.fetchedObjects.count;
            break;
    }
    return count;
}

- (CGFloat)lineGraph:(BEMSimpleLineGraphView *)graph valueForPointAtIndex:(NSInteger)index
{
    RecordLog *recordLog;
    CGFloat pointValue;

    switch (self.lineType) {
        case GCLineTypeGlucose:
            recordLog = [self.GfetchController.fetchedObjects objectAtIndex:index];
            pointValue = recordLog.detectLog.glucose.floatValue;
            break;
        case GCLineTypeHemo:
            recordLog = [self.HfetchController.fetchedObjects objectAtIndex:index];
            pointValue = recordLog.detectLog.hemoglobinef.floatValue;
            break;

    }
    return pointValue;
}

- (GraphSearchMode)searchModeInLineGraph:(BEMSimpleLineGraphView *)graph
{
    switch (self.searchMode) {
        case GCSearchModeByDay:
            return GraphSearchModeByDay;
        case GCSearchModeByMonth:
            return GraphSearchModeByMonth;
    }
}

- (CGFloat)intervalForSecondInLineGraph:(BEMSimpleLineGraphView *)graph
{
    switch (self.searchMode) {
        case GCSearchModeByDay:
            return 1.0/60;
        case GCSearchModeByMonth:
            return 0.0005;
    }
}

- (CGFloat)intervalForDayInLineGraph:(BEMSimpleLineGraphView *)graph
{
    return 30;
}

- (CGFloat)maxValueForLineGraph:(BEMSimpleLineGraphView *)graph
{
    return 30.0;
}

- (CGFloat)minValueForLineGraph:(BEMSimpleLineGraphView *)graph
{
    return 3.5;
}

#pragma mark - trackerChart Delegate

- (NSInteger)numberOfGapsBetweenLabelsOnLineGraph:(BEMSimpleLineGraphView *)graph
{
    return 0;
}

- (NSInteger)numberOfYAxisLabelsOnLineGraph:(BEMSimpleLineGraphView *)graph
{
    return 12;
}

//- (void)lineGraph:(BEMSimpleLineGraphView *)graph didTapPointAtIndex:(NSInteger)index
//{
//    hud = [[MBProgressHUD alloc] initWithView:self.view];
//    [self.view addSubview:hud];
//    
//    hud.customView = self.detailView;
//    hud.margin = 0;
//    hud.cornerRadius = 0;
//    hud.mode = MBProgressHUDModeCustomView;
//    hud.delegate = self;
//    
//    [hud show:YES];
//    
//    return NSLog(@"Tap on the key point at index: %ld",(long)index);
//}

- (NSDate *)currentDateInLineGraph:(BEMSimpleLineGraphView *)graph
{
    return self.selectedDate;
}

- (NSDate *)lineGraph:(BEMSimpleLineGraphView *)graph dateOnXAxisForIndex:(NSInteger)index
{
    RecordLog *recordLog;
    switch (self.lineType) {
        case GCLineTypeGlucose:
            if (self.GfetchController.fetchedObjects.count == 0) {
                return nil;
            }
            recordLog = [self.GfetchController.fetchedObjects objectAtIndex:index];
            break;
        case GCLineTypeHemo:
            if (self.HfetchController.fetchedObjects.count == 0) {
                return nil;
            }
            recordLog = [self.HfetchController.fetchedObjects objectAtIndex:index];
            break;

    }
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyyMMddHHmmss"];
    return [dateFormatter dateFromString:recordLog.time];
}

//- (NSString *)lineGraph:(BEMSimpleLineGraphView *)graph labelOnXAxisForIndex:(NSInteger)index
//{
//    if (self.fetchController.fetchedObjects.count == 0) {
//        return @"";
//    }
//    
//    RecordLog *recordLog = [self.fetchController.fetchedObjects objectAtIndex:index];
//    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
////    [dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"]];
//    [dateFormatter setDateFormat:@"yyyyMMddHHmmss"];
//    NSDate *date = [dateFormatter dateFromString:recordLog.time];
//    [dateFormatter setDateFormat:@"MM/dd HH:mm"];
//    NSString *dateString = [dateFormatter stringFromDate:date] ? [dateFormatter stringFromDate:date] : @"";
//    
//    return [dateString stringByReplacingOccurrencesOfString:@" " withString:@"\n"];
//}

- (BOOL)noDataLabelEnableForLineGraph:(BEMSimpleLineGraphView *)graph
{
    return YES;
}

#pragma mark - TableView

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    NSInteger sections;
    switch (self.lineType) {
        case GCLineTypeGlucose:
            if (self.GfetchController.fetchedObjects.count > 0 ) {
                sections = [self.GfetchController.sections count];
            }else{
                sections = 0;
            }
            break;
            
        case GCLineTypeHemo:
            if (self.HfetchController.fetchedObjects.count > 0 ) {
                sections = [self.GfetchController.sections count];

            }else{
                sections = 0;
            }
            break;
    }
    return sections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger rows;
    switch (self.lineType) {
        case GCLineTypeGlucose:
            rows = self.GfetchController.fetchedObjects.count;
            break;
        case GCLineTypeHemo:
            rows = self.HfetchController.fetchedObjects.count;
            break;

    }
    return rows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"DetectCell";
    DetectDataCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    [self configureTableView:tableView withCell:cell atIndexPath:indexPath];
    return cell;
}

- (void)configureTableView:(UITableView *)tableView withCell:(DetectDataCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    RecordLog *recordLog;
    
    switch (self.lineType) {
        case GCLineTypeGlucose:
            recordLog = [self.GfetchController.fetchedObjects objectAtIndex:indexPath.row];
            cell.detectValue.text = recordLog.detectLog.glucose;
            break;
        case GCLineTypeHemo:
            recordLog = [self.HfetchController.fetchedObjects objectAtIndex:indexPath.row];
            cell.detectValue.text = recordLog.detectLog.hemoglobinef;
            break;
    }
    
    cell.detectDate.text = [NSString formattingDateString:recordLog.time From:@"yyyyMMddHHmmss" to:@"yyyy-MM-dd, EEEE"];
    cell.detectTime.text = [NSString formattingDateString:recordLog.time From:@"yyyyMMddHHmmss" to:@"HH:mm"];


}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Others

- (IBAction)detailBtn:(id)sender
{
    [hud hide:YES afterDelay:0.1];
    
}

- (void)showDateSelectionVC
{
    [RMDateSelectionViewController setLocalizedTitleForCancelButton:NSLocalizedString(@"Cancel", nil)];
    [RMDateSelectionViewController setLocalizedTitleForNowButton:NSLocalizedString(@"30 days recently", nil)];
    [RMDateSelectionViewController setLocalizedTitleForSelectButton:NSLocalizedString(@"Select By Day", nil)];
    
    RMDateSelectionViewController *dateSelectionVC = [RMDateSelectionViewController dateSelectionController];
    dateSelectionVC.delegate = self;
    dateSelectionVC.disableBlurEffects = YES;
    dateSelectionVC.disableBouncingWhenShowing = NO;
    dateSelectionVC.disableMotionEffects = NO;
    dateSelectionVC.blurEffectStyle = UIBlurEffectStyleExtraLight;
    dateSelectionVC.datePicker.datePickerMode = UIDatePickerModeDate;
    
    [dateSelectionVC show];
}

- (void)dateSelectionViewControllerNowButtonPressed:(RMDateSelectionViewController *)vc
{
    [vc dismiss];
    self.searchMode = GCSearchModeByMonth;
    NSDate *date = vc.datePicker.date;
    self.selectedDate = date;
    self.dateLabel.text = NSLocalizedString(@"A month earlier", nil);
    self.trackerChart.sizePoint = 1;
    [self configureFetchController];
    [self getDetectionData];
}

- (void)dateSelectionViewController:(RMDateSelectionViewController *)vc didSelectDate:(NSDate *)aDate
{
    self.searchMode = GCSearchModeByDay;
    self.selectedDate = aDate;
    self.dateLabel.text = [NSString formattingDate:self.selectedDate to:@"yyyy-MM-dd"];
    self.trackerChart.sizePoint = 10;
    [self configureFetchController];
    [self getDetectionData];
}

- (void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item
{

    if ([item isEqual:[tabBar.items objectAtIndex:0]] ) {
        self.lineType = GCLineTypeGlucose;
        self.unitLabel.text = @"mmol/L";
    }else{
        self.lineType = GCLineTypeHemo;
        self.unitLabel.text = @"%";
    }
    [self configureFetchController];

}

@end
