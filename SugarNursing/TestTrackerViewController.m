//
//  TestTrackerViewController.m
//  SugarNursing
//
//  Created by Dan on 14-11-10.
//  Copyright (c) 2014年 Tisson. All rights reserved.
//

#import "TestTrackerViewController.h"
#import "UtilsMacro.h"

typedef NS_ENUM(NSInteger, GCSearchMode) {
    GCSearchModeByDay = 0,
    GCSearchModeByMonth
};

@interface TestTrackerViewController ()<MBProgressHUDDelegate, NSFetchedResultsControllerDelegate, RMDateSelectionViewControllerDelegate>{
    MBProgressHUD *hud;
}

@property (strong, nonatomic) NSFetchedResultsController *fetchController;
@property (strong, nonatomic) NSString *lineType;
@property (strong, nonatomic) NSDate *selectedDate;
@property (assign) GCSearchMode searchMode;
@property (weak, nonatomic) IBOutlet UILabel *unitLabel;

@end

@implementation TestTrackerViewController



- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // lineType  1:glucose 2:hemoglobin
    self.lineType = @"1";
    self.unitLabel.text = @"mmol/L";
    self.selectedDate = [NSDate date];
    self.searchMode = GCSearchModeByDay;
    
    [self setBarRightItems];
    [self.tabBar setSelectedItem:[self.tabBar items][0]];
    if ([self respondsToSelector:@selector(automaticallyAdjustsScrollViewInsets)]) {
        self.automaticallyAdjustsScrollViewInsets = NO;
    }
    
    [self configureGraph];
    [self getDetectionData];
}

#pragma mark - FetchController Delegate

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self.trackerChart reloadGraph];
}

- (void)configureFetchController
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    NSString *eventObject;
    
    switch (self.searchMode) {
        case GCSearchModeByDay:
        {
            [dateFormatter setDateFormat:@"yyyyMMdd"];
            break;
        }
        case GCSearchModeByMonth:
        {
            [dateFormatter setDateFormat:@"yyyyMM"];

        }
        default:
            break;
    }
    
    if ([self.lineType isEqualToString:@"1"]){
        eventObject = @"glucose";
    }else{
        eventObject = @"hemoglobin";
    }

    NSString *dateString = [dateFormatter stringFromDate:self.selectedDate];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"logType = %@ && ANY eventList.eventObject = [cd] %@ && userid.userId = %@ && userid.linkManId = %@ && time beginswith[cd] %@" ,@"detect",eventObject,[NSString userID],[NSString linkmanID],dateString];
    
    self.fetchController = [RecordLog fetchAllGroupedBy:nil sortedBy:@"time" ascending:YES withPredicate:predicate delegate:self incontext:[CoreDataStack sharedCoreDataStack].context];
    
    [self.trackerChart reloadGraph];
}

- (void)getDetectionData
{
    [self configureFetchController];
    
    hud = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
    [self.navigationController.view addSubview:hud];
    hud.mode = MBProgressHUDModeText;
    
    NSMutableDictionary *parameters = [@{@"method":@"queryDetectLine",
                                         @"sign":@"sign",
                                         @"sessionId":[NSString sessionID],
                                         @"linkManId":[NSString linkmanID],
                                         @"lineType":self.lineType,
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
                for (RecordLog *recordLog in self.fetchController.fetchedObjects) {
                    [recordLog deleteEntityInContext:[CoreDataStack sharedCoreDataStack].context];
                }
                
                NSArray *recordLogArray = [responseData objectForKey:@"pointList"];
                
                for (NSDictionary *recordLogDic in recordLogArray) {
                    
                    RecordLog *recordLog = [RecordLog createEntityInContext:[CoreDataStack sharedCoreDataStack].context];
                    [recordLog updateCoreDataForData:recordLogDic withKeyPath:nil];

                    UserID *userId = [UserID createEntityInContext:[CoreDataStack sharedCoreDataStack].context];
                    userId.userId = [NSString userID];
                    userId.linkManId = [NSString linkmanID];
                    recordLog.userid = userId;
                    
                    NSMutableOrderedSet *evenLists = [[NSMutableOrderedSet alloc] initWithCapacity:1];

                    for (NSDictionary *evenListDic in [recordLogDic objectForKey:@"eventList"]) {
                        RecordLogList *eventList = [RecordLogList createEntityInContext:[CoreDataStack sharedCoreDataStack].context];
                        [eventList updateCoreDataForData:evenListDic withKeyPath:nil];
                        [evenLists addObject:eventList];
                    }
    
                    recordLog.eventList = evenLists;
                }
                
                [[CoreDataStack sharedCoreDataStack] saveContext];
                hud.labelText = NSLocalizedString(@"Data Updated", nil);
                [hud show:YES];
                [hud hide:YES afterDelay:HUD_TIME_DELAY];
            }else{
                hud.labelText = [NSString localizedMsgFromRet_code:ret_code];
                [hud hide:YES afterDelay:HUD_TIME_DELAY];
            }
        }else{
            hud.labelText = [error localizedDescription];
            [hud show:YES];
            [hud hide:YES afterDelay:HUD_TIME_DELAY];
        }
        
    }];
   
}

#pragma mark - Configuration

- (void )setBarRightItems
{
//    UIButton *shareBtn = [UIButton buttonWithType:UIButtonTypeCustom];
//    shareBtn.frame = CGRectMake(0, 0, 26, 26);
//    shareBtn.tag = 11;
//    [shareBtn setImage:[UIImage imageNamed:@"Share.png"] forState:UIControlStateNormal];
//    [shareBtn addTarget:self action:@selector(leftBarButtonAction:) forControlEvents:UIControlEventTouchUpInside];
//    UIBarButtonItem *share = [[UIBarButtonItem alloc] initWithCustomView:shareBtn];
    

    
    UIButton *calenderBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    calenderBtn.frame = CGRectMake(0, 0, 26, 26);
    calenderBtn.tag = 12;
    [calenderBtn setImage:[UIImage imageNamed:@"Calender.png"] forState:UIControlStateNormal];
    [calenderBtn addTarget:self action:@selector(leftBarButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *calender = [[UIBarButtonItem alloc] initWithCustomView:calenderBtn];
    
    self.navigationItem.rightBarButtonItems = @[calender];
}

- (void)leftBarButtonAction:(id)sender
{
    UIButton *btn = (UIButton *)sender;
    switch (btn.tag) {
        case 11:
        {
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
//    self.trackerChart.alwaysDisplayPopUpLabels = YES;
    self.trackerChart.enableReferenceXAxisLines = YES;
    self.trackerChart.enableReferenceYAxisLines = YES;
    self.trackerChart.enableReferenceAxisFrame = YES;
    self.trackerChart.animationGraphStyle = BEMLineAnimationDraw;
}

#pragma mark - trackerChart Data Source

- (NSInteger)numberOfPointsInLineGraph:(BEMSimpleLineGraphView *)graph
{
    return self.fetchController.fetchedObjects.count;
}

- (CGFloat)lineGraph:(BEMSimpleLineGraphView *)graph valueForPointAtIndex:(NSInteger)index
{
    RecordLog *recordLog = [self.fetchController.fetchedObjects objectAtIndex:index];
    RecordLogList *logList = recordLog.eventList[0];
    return [logList.eventValue floatValue];
}

- (CGFloat)intervalForAnHourInLineGraph:(BEMSimpleLineGraphView *)graph
{
    return 30;
}

- (CGFloat)maxValueForLineGraph:(BEMSimpleLineGraphView *)graph
{
    return 12.0;
}

- (CGFloat)minValueForLineGraph:(BEMSimpleLineGraphView *)graph
{
    return 2;
}

#pragma mark - trackerChart Delegate

- (NSInteger)numberOfGapsBetweenLabelsOnLineGraph:(BEMSimpleLineGraphView *)graph
{
    return 0;
}

- (NSInteger)numberOfYAxisLabelsOnLineGraph:(BEMSimpleLineGraphView *)graph
{
    return 6;
}

- (void)lineGraph:(BEMSimpleLineGraphView *)graph didTapPointAtIndex:(NSInteger)index
{
    hud = [[MBProgressHUD alloc] initWithView:self.view];
    [self.view addSubview:hud];
    
    hud.customView = self.detailView;
    hud.margin = 0;
    hud.cornerRadius = 0;
    hud.mode = MBProgressHUDModeCustomView;
    hud.delegate = self;
    
    [hud show:YES];
    
    return NSLog(@"Tap on the key point at index: %ld",(long)index);
}

- (NSDate *)lineGraph:(BEMSimpleLineGraphView *)graph dateOnXAxisForIndex:(NSInteger)index
{
    if (self.fetchController.fetchedObjects.count == 0) {
        return nil;
    }
    
    RecordLog *recordLog = [self.fetchController.fetchedObjects objectAtIndex:index];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyyMMddHHmmss"];
    return [dateFormatter dateFromString:recordLog.time];
}

- (NSString *)lineGraph:(BEMSimpleLineGraphView *)graph labelOnXAxisForIndex:(NSInteger)index
{
    if (self.fetchController.fetchedObjects.count == 0) {
        return @"";
    }
    
    RecordLog *recordLog = [self.fetchController.fetchedObjects objectAtIndex:index];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
//    [dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"]];
    [dateFormatter setDateFormat:@"yyyyMMddHHmmss"];
    NSDate *date = [dateFormatter dateFromString:recordLog.time];
    [dateFormatter setDateFormat:@"MM/dd HH:mm"];
    NSString *dateString = [dateFormatter stringFromDate:date] ? [dateFormatter stringFromDate:date] : @"";
    
    return [dateString stringByReplacingOccurrencesOfString:@" " withString:@"\n"];
}

- (BOOL)noDataLabelEnableForLineGraph:(BEMSimpleLineGraphView *)graph
{
    return YES;
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
    [self configureFetchController];
    [self getDetectionData];
}

- (void)dateSelectionViewController:(RMDateSelectionViewController *)vc didSelectDate:(NSDate *)aDate
{
    self.searchMode = GCSearchModeByDay;
    self.selectedDate = aDate;
    [self configureFetchController];
    [self getDetectionData];
}



- (void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item
{

    if ([item isEqual:[tabBar.items objectAtIndex:0]] ) {
        self.lineType = @"1";
        self.unitLabel.text = @"mmol/L";
        [self getDetectionData];
    }else{
        self.lineType = @"2";
        self.unitLabel.text = @"%";
        [self getDetectionData];
        
    }

}

@end
