//
//  RecoveryLogDetailViewController.m
//  SugarNursing
//
//  Created by Dan on 14-11-20.
//  Copyright (c) 2014年 Tisson. All rights reserved.
//

#import "RecoveryLogDetailViewController.h"
#import "BasicCell.h"
#import "FeelingCell.h"
#import "DetectCell.h"
#import "MedicateCell.h"
#import "DietCell.h"
#import "ExerciseCell.h"
#import "LogSectionHeaderView.h"
#import "SwipeView.h"
#import "UtilsMacro.h"

#define NUMBERS @"0123456789."
#define DIET_PATH [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"diet.plist"]
#define DIET_RATE_PATH [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"diet_rate.plist"]
#define EXERCISE_PATH [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"exercise.plist"]
#define EXERCISE_RATE_PATH [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"exercise_rate.plist"]
#define INSULIN_PATH [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"insulin.plist"]
#define DRUGS_PATH [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"drugs.plist"]

static NSString *BasicCellIdentifier = @"BasicCell";
static NSString *FeelingCellIdentifier = @"FeelingCell";
static NSString *DetectCellIdentifier = @"DetectCell";
static NSString *MediacteCellIdentifier = @"MedicateCell";
static NSString *DietCellIdentifier = @"DietCell";
static NSString *ExerciseCellIndentifier = @"ExerciseCell";

static NSString *SectionHeaderViewIdentifier = @"SectionHeaderViewIdentifier";


#define HEADER_HEIGHT 30



@interface RecoveryLogDetailViewController ()<UITextFieldDelegate,SwipeViewDataSource, SwipeViewDelegate, UITableViewDataSource, UITableViewDelegate, UITabBarDelegate, UIActionSheetDelegate, UINavigationControllerDelegate, LogSectionHeaderViewDelegate, UIPickerViewDataSource, UIPickerViewDelegate,UIAlertViewDelegate>{
    MBProgressHUD *hud;
}

@property (weak, nonatomic) IBOutlet SwipeView *swipeView;
@property (weak, nonatomic) IBOutlet UITabBar *tabBar;

@property (strong, nonatomic) UITableView *detectView;
@property (strong, nonatomic) UITableView *drugView;
@property (strong, nonatomic) UITableView *dietView;
@property (strong, nonatomic) UITableView *exerciseView;

@property (strong, nonatomic) UIActionSheet *sheet;

@property (weak, nonatomic) IBOutlet UIDatePicker *datePicker;
@property (strong, nonatomic) IBOutlet UIView *datePickerView;
@property (strong, nonatomic) IBOutlet UIView *pickerViewWrapper;
@property (weak, nonatomic) IBOutlet UIPickerView *pickerView;
@property (weak, nonatomic) IBOutlet UILabel *fieldLabel;

@property (strong, nonatomic) NSIndexPath *selectedIndexPath;
//detect
@property (strong, nonatomic) NSMutableArray *feelingArray;
//drug
@property (strong, nonatomic) NSMutableArray *insulinArray;
@property (strong, nonatomic) NSMutableArray *drugsArray;
@property (strong, nonatomic) NSMutableArray *othersArray;
@property (strong, nonatomic) NSMutableArray *medicationData;
@property (strong, nonatomic) NSMutableArray *drugData;
@property (strong, nonatomic) NSMutableArray *insulinData;
//diet
@property (strong, nonatomic) NSMutableArray *dietArray;
@property (strong, nonatomic) NSMutableArray *dietData;
@property (strong, nonatomic) NSDictionary *dietRate;
//exercise
@property (strong, nonatomic) NSMutableArray *exerciseData;
@property (strong, nonatomic) NSMutableArray *exercisePickerData;
@property (strong, nonatomic) NSDictionary *exerciseRate;


@property (strong, nonatomic) NSString *date;
@property (strong, nonatomic) NSString *time;
@property (strong, nonatomic) NSString *remark;
@property (strong, nonatomic) NSString *period;
@property (strong, nonatomic) NSString *gluco;
@property (strong, nonatomic) NSString *hemo;


@end

@implementation RecoveryLogDetailViewController

- (void)dataSetup
{
    self.selectedIndexPath = nil;

    switch (self.recoveryLogType) {
        case RecoveryLogTypeDetect:
        {
            if (!self.feelingArray) {
                self.feelingArray = [[NSMutableArray alloc] initWithCapacity:10];
            }

            if (self.recoveryLogStatus == RecoveryLogStatusEdit) {
                self.gluco = self.recordLog.detectLog.glucose;
                self.hemo = self.recordLog.detectLog.hemoglobinef;
                NSArray *feeling = [self.recordLog.detectLog.selfSense componentsSeparatedByString:@","];
                [self.feelingArray addObjectsFromArray:feeling];
            }
            
            break;
        }
        case RecoveryLogTypeDrug:
        {
            if (!self.insulinArray) {
                self.insulinArray = [[NSMutableArray alloc] initWithCapacity:10];
            }
            if (!self.drugsArray) {
                self.drugsArray = [[NSMutableArray alloc] initWithCapacity:10];
            }
            if (!self.othersArray) {
                self.othersArray = [[NSMutableArray alloc] initWithCapacity:10];
            }
            
            if (self.recoveryLogStatus == RecoveryLogStatusEdit) {
                NSPredicate *predicate = [NSPredicate predicateWithFormat:@"drugLog = %@ && sort = %@",self.recordLog.drugLog, @"降糖药"];
                [self.drugsArray addObjectsFromArray:[Medicine findAllWithPredicate:predicate inContext:[CoreDataStack sharedCoreDataStack].context]];
                
                NSPredicate *predicate1 = [NSPredicate predicateWithFormat:@"drugLog = %@ && sort = %@",self.recordLog.drugLog, @"胰岛素"];
                [self.insulinArray addObjectsFromArray:[Medicine findAllWithPredicate:predicate1 inContext:[CoreDataStack sharedCoreDataStack].context]];
                
                NSPredicate *predicate2 = [NSPredicate predicateWithFormat:@"drugLog = %@ && sort = %@",self.recordLog.drugLog, @"其他"];
                [self.othersArray addObjectsFromArray:[Medicine findAllWithPredicate:predicate2 inContext:[CoreDataStack sharedCoreDataStack].context]];
            }
            
            [self loadDrugDataSource];
            break;
        }
        case RecoveryLogTypeDiet:
        {
            if (!self.dietArray) {
                self.dietArray = [[NSMutableArray alloc] initWithCapacity:10];
            }
            
            if (self.recoveryLogStatus == RecoveryLogStatusEdit) {
                NSPredicate *predicate = [NSPredicate predicateWithFormat:@"dietLog = %@",self.recordLog.dietLog];
                [self.dietArray addObjectsFromArray:[Food findAllWithPredicate:predicate inContext:[CoreDataStack sharedCoreDataStack].context]];
                
            }
            [self loadDietDataSource];
            break;
        }
        case RecoveryLogTypeExercise:
            [self loadExerciseDataSource];
            break;
    }

   
}

- (void)loadDrugDataSource
{
    if (![[NSFileManager defaultManager] fileExistsAtPath:INSULIN_PATH]) {
        NSString *insulinPath = [[NSBundle mainBundle] pathForResource:@"Insulin" ofType:@"plist"];
        self.insulinData= [[NSMutableArray alloc] initWithContentsOfFile:insulinPath];
        [self.insulinData writeToFile:INSULIN_PATH atomically:YES];
    }else self.insulinData = [NSMutableArray arrayWithContentsOfFile:INSULIN_PATH];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:DRUGS_PATH]) {
        NSString *drugsPath = [[NSBundle mainBundle] pathForResource:@"Drugs" ofType:@"plist"];
        self.drugData = [[NSMutableArray alloc] initWithContentsOfFile:drugsPath];
        [self.drugData writeToFile:DRUGS_PATH atomically:YES];
    }else self.drugData = [NSMutableArray arrayWithContentsOfFile:DRUGS_PATH];
    
    NSArray *usageArr = @[NSLocalizedString(@"Oral", nil),
                          NSLocalizedString(@"Insulin", nil),
                          NSLocalizedString(@"Injection", nil)
                          ];
    NSArray *unitArr = @[NSLocalizedString(@"mg", nil),
                         NSLocalizedString(@"g", nil),
                         NSLocalizedString(@"grain", nil),
                         NSLocalizedString(@"slice", nil),
                         NSLocalizedString(@"unit", nil),
                         NSLocalizedString(@"ml", nil),
                         NSLocalizedString(@"piece", nil),
                         NSLocalizedString(@"bottle", nil)
                         ];
    NSArray *medicateDataDefault = @[
                                     @{@"01":self.insulinData,
                                       @"02":self.drugData},
                                     usageArr,
                                     unitArr
                                     ];
    self.medicationData = [NSMutableArray arrayWithArray:medicateDataDefault];

}

- (void)loadDietDataSource
{
    if (![[NSFileManager defaultManager] fileExistsAtPath:DIET_PATH]) {
        NSString *foodPath = [[NSBundle mainBundle] pathForResource:@"food" ofType:@"plist"];
        self.dietData = [NSMutableArray arrayWithContentsOfFile:foodPath];
        [self.dietData writeToFile:DIET_PATH atomically:YES];
    }else self.dietData = [NSMutableArray arrayWithContentsOfFile:DIET_PATH];

    if (![[NSFileManager defaultManager] fileExistsAtPath:DIET_RATE_PATH]) {
        NSString *foodRate = [[NSBundle mainBundle] pathForResource:@"foodRate" ofType:@"plist"];
        self.dietRate = [NSDictionary dictionaryWithContentsOfFile:foodRate];
        [self.dietRate writeToFile:DIET_RATE_PATH atomically:YES];

    }else self.dietRate = [NSDictionary dictionaryWithContentsOfFile:DIET_RATE_PATH];

}

- (void)loadExerciseDataSource
{
    if (![[NSFileManager defaultManager] fileExistsAtPath:EXERCISE_PATH]) {
        NSString *exercisePath = [[NSBundle mainBundle] pathForResource:@"exercise" ofType:@"plist"];
        self.exerciseData = [NSMutableArray arrayWithContentsOfFile:exercisePath];
        [self.exerciseData writeToFile:EXERCISE_PATH atomically:YES];
    }else self.exerciseData  = [NSMutableArray arrayWithContentsOfFile:EXERCISE_PATH];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:EXERCISE_RATE_PATH]) {
        NSString *ratePath = [[NSBundle mainBundle] pathForResource:@"exerciseRate" ofType:@"plist"];
        self.exerciseRate = [NSDictionary dictionaryWithContentsOfFile:ratePath];
        [self.exerciseRate writeToFile:EXERCISE_RATE_PATH atomically:YES];
    }else self.exerciseRate = [NSDictionary dictionaryWithContentsOfFile:EXERCISE_RATE_PATH];
    
    NSArray *exerciseDefault =@[
        self.exerciseData,
        @[@"10",@"15",@"20",@"25",@"30",@"35",@"40",@"45",@"50",@"55",@"60",],
        @[NSLocalizedString(@"minutes",nil)]];
    
    self.exercisePickerData = [NSMutableArray arrayWithArray:exerciseDefault];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    switch (self.recoveryLogStatus) {
        case RecoveryLogStatusAdd:
        {
            self.title = NSLocalizedString(@"Add New Recovery Record", nil);
            self.tabBar.selectedItem = [self.tabBar.items objectAtIndex:0];
            break;
        }
        case RecoveryLogStatusEdit:
        {
            self.title = NSLocalizedString(@"Edit Recovery Record", nil);
            self.tabBar.alpha = 0;
            break;
        }
    }
    [self configureSaveBtn];
    self.swipeView.scrollEnabled = NO;
    
}

- (void)configureSaveBtn
{
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(save:)];
}

- (void)save:(id)sender
{
    [self.view endEditing:YES];
    switch (self.recoveryLogType) {
        case RecoveryLogTypeDetect:
        {
            [self editDetectLog];
            break;
        }
        case RecoveryLogTypeDrug:
        {
            [self editDrugLog];
            break;
        }
        case RecoveryLogTypeDiet:
        {
            [self editDietLog];
            break;
        }

        case RecoveryLogTypeExercise:
        {
            [self editExerciseLog];
            break;
        }
        default:
            break;
    }
    
}

- (void)editDetectLog
{
    MBProgressHUD *aHud = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
    [self.navigationController.view addSubview:aHud];
    aHud.labelText = NSLocalizedString(@"Saving Data", nil);
    [aHud show:YES];
    
    if ([self.gluco isEqualToString:@""] && [self.hemo isEqualToString:@""]) {
        aHud.mode = MBProgressHUDModeText;
        aHud.labelText = NSLocalizedString(@"Value cannot be empty", nil);
        [aHud hide:YES afterDelay:HUD_TIME_DELAY];
        return;
    }
    
    NSString *dateTime = [NSString stringWithFormat:@"%@ %@",self.date,self.time];
    dateTime = [NSString formattingDateString:dateTime From:@"yyyy-MM-dd HH:mm" to:@"yyyyMMddHHmmss"];
    
    NSMutableArray *feelingArray_ = [self.feelingArray mutableCopy];
    [feelingArray_ enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSString *formattingFeel = [NSString formattingFeeling:(NSString *)obj];
        if (formattingFeel) {
            [feelingArray_ replaceObjectAtIndex:idx withObject:formattingFeel];
        }
        
    }];
    
    NSString *feeling = [feelingArray_ componentsJoinedByString:@","];
    
    __block NSMutableDictionary *parameters = [@{@"method":@"detectLogEdit",
                                 @"sign":@"sign",
                                 @"sessionId":[NSString sessionID],
                                 @"linkManId":[NSString linkmanID],
                                 @"detectTime":dateTime ? dateTime : @"",
                                 @"glucose":self.gluco,
                                 @"hemoglobinef":self.hemo,
                                 @"selfSense":feeling ? feeling :@"",
                                 @"remar":self.remark ? self.remark :@"",
                                 } mutableCopy];
    
    switch (self.recoveryLogStatus) {
        case RecoveryLogStatusAdd:
        {
            break;
        }
        case RecoveryLogStatusEdit:
        {
            [parameters setValue:self.recordLog.detectLog.detectId forKey:@"detectId"];
            break;
        }
    }
    
    [GCRequest userEditDetectLogWithParameters:parameters withBlock:^(NSDictionary *responseData, NSError *error) {
        aHud.mode = MBProgressHUDModeText;
        if (!error) {
            NSString *ret_code = [responseData valueForKey:@"ret_code"];
            if ([ret_code isEqualToString:@"0"]) {
                aHud.labelText = NSLocalizedString(@"Data Updated", nil);
                
                // CoreData 中数据的更新通知只有对其属性的修改有效，如果是其属性的属性进行修改，则通知会无效化
                
                DetectLog *detectLog;
                switch (self.recoveryLogStatus) {
                    case RecoveryLogStatusEdit:
                        
                        detectLog = self.recordLog.detectLog;
                        [detectLog updateCoreDataForData:parameters withKeyPath:nil];
                        detectLog.selfSense = [self.feelingArray componentsJoinedByString:@","];
                        
                        
                        self.recordLog.time = dateTime;
                        self.recordLog.detectLog = detectLog;
                        break;
                    case RecoveryLogStatusAdd:
                    {
                        RecordLog *recordLog = [RecordLog createEntityInContext:[CoreDataStack sharedCoreDataStack].context];
                        recordLog.logType = @"detect";
                        recordLog.time = dateTime ;
                        recordLog.id = [NSString stringWithFormat:@"%@",[responseData valueForKey:@"detectId"]];
                        NSLog(@"id = %@",recordLog.id);
                        
                        UserID *userId = [UserID createEntityInContext:[CoreDataStack sharedCoreDataStack].context];
                        userId.userId = [NSString userID];
                        userId.linkManId = [NSString linkmanID];
                        
                        detectLog = [DetectLog createEntityInContext:[CoreDataStack sharedCoreDataStack].context];
                        [detectLog updateCoreDataForData:parameters withKeyPath:nil];
                        detectLog.selfSense = [self.feelingArray componentsJoinedByString:@","];
                        detectLog.detectId = recordLog.id;

                        
                        recordLog.userid = userId;
                        recordLog.detectLog = detectLog;
                        break;
                    }
    
                }
                [[CoreDataStack sharedCoreDataStack] saveContext];
                double delayInSeconds = 1.35;
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self.navigationController popViewControllerAnimated:YES];
                });
            }else{
                aHud.labelText = [NSString localizedMsgFromRet_code:ret_code withHUD:YES];
            }
        }else{
            aHud.labelText = NSLocalizedString(@"Server is busy", nil);
        }
        
        [aHud hide:YES afterDelay:HUD_TIME_DELAY];
        
    }];
}

- (void)editDrugLog
{
    MBProgressHUD *aHud = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
    [self.navigationController.view addSubview:aHud];
    aHud.labelText = NSLocalizedString(@"Saving Data", nil);
    [aHud show:YES];
    
    if (self.insulinArray.count == 0 && self.drugsArray.count == 0 && self.othersArray.count == 0) {
        aHud.mode = MBProgressHUDModeText;
        aHud.labelText = NSLocalizedString(@"用药不能为空", nil);
        [aHud hide:YES afterDelay:HUD_TIME_DELAY];
        return;
    }
    
    NSString *dateTime = [NSString stringWithFormat:@"%@ %@",self.date,self.time];
    dateTime = [NSString formattingDateString:dateTime From:@"yyyy-MM-dd HH:mm" to:@"yyyyMMddHHmmss"];
    
    NSMutableArray *medicineList = [[NSMutableArray alloc] initWithCapacity:10];
    NSMutableOrderedSet *medicineSet = [[NSMutableOrderedSet alloc] initWithCapacity:10];
    
    [self.insulinArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        Medicine *medicine = (Medicine *)obj;
        if (!medicine.dose || !medicine.drug || !medicine.unit || !medicine.usage || !medicine.sort) {
            return;
        }
        NSString *unit = [NSString formattingUnit:medicine.unit];
        NSString *usage = [NSString formattingUsage:medicine.usage];
        NSNumber *dose = [NSNumber numberWithFloat:medicine.dose.floatValue];
        NSDictionary *medicineDic = @{@"dose":dose?dose:0,
                                      @"drug":medicine.drug?medicine.drug:@"",
                                      @"sort":medicine.sort?medicine.sort:@"",
                                      @"unit":unit?unit:@"",
                                      @"usage":usage?usage:@""};
        
        [medicineSet addObject:medicine];
        [medicineList addObject:medicineDic];
    }];
    
    
    [self.drugsArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        Medicine *medicine = (Medicine *)obj;
        if (!medicine.dose || !medicine.drug || !medicine.unit || !medicine.usage || !medicine.sort) {
            return;
        }
        NSString *unit = [NSString formattingUnit:medicine.unit];
        NSString *usage = [NSString formattingUsage:medicine.usage];
        NSNumber *dose = [NSNumber numberWithFloat:medicine.dose.floatValue];
        NSDictionary *medicineDic = @{@"dose":dose?dose:0,
                                      @"drug":medicine.drug?medicine.drug:@"",
                                      @"sort":medicine.sort?medicine.sort:@"",
                                      @"unit":unit?unit:@"",
                                      @"usage":usage?usage:@""};
        [medicineSet addObject:medicine];
        [medicineList addObject:medicineDic];
    }];
    
    [self.othersArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        Medicine *medicine = (Medicine *)obj;
        if (!medicine.dose || !medicine.drug || !medicine.unit || !medicine.usage || !medicine.sort) {
            return;
        }
        NSString *unit = [NSString formattingUnit:medicine.unit];
        NSString *usage = [NSString formattingUsage:medicine.usage];
        NSNumber *dose = [NSNumber numberWithFloat:medicine.dose.floatValue];
        NSDictionary *medicineDic = @{@"dose":dose?dose:0,
                                      @"drug":medicine.drug?medicine.drug:@"",
                                      @"sort":medicine.sort?medicine.sort:@"",
                                      @"unit":unit?unit:@"",
                                      @"usage":usage?usage:@""};
        [medicineSet addObject:medicine];
        [medicineList addObject:medicineDic];
    }];
    
    NSString *jsonString = [medicineList JSONString];
    
    __block NSMutableDictionary *parameters = [@{@"method":@"drugLogEdit",
                                                 @"sign":@"sign",
                                                 @"sessionId":[NSString sessionID],
                                                 @"linkManId":[NSString linkmanID],
                                                 @"medicineTime":dateTime ? dateTime : @"",
                                                 @"medicineList":jsonString,
                                                 } mutableCopy];
    
    switch (self.recoveryLogStatus) {
        case RecoveryLogStatusEdit:
            [parameters setValue:self.recordLog.drugLog.medicineId forKey:@"medicineId"];
            break;
        case RecoveryLogStatusAdd:
            break;
    }
    
    [GCRequest userEditDrugLogWithParameters:parameters withBlock:^(NSDictionary *responseData, NSError *error) {
        aHud.mode = MBProgressHUDModeText;
        if (!error) {
            NSString *ret_code = [responseData valueForKey:@"ret_code"];
            if ([ret_code isEqualToString:@"0"]) {
                aHud.labelText = NSLocalizedString(@"Data Updated", nil);
                
                switch (self.recoveryLogStatus) {
                    case RecoveryLogStatusEdit:
                    {
                        DrugLog *drugLog;
                        drugLog = self.recordLog.drugLog;
                        drugLog.medicineTime = dateTime;
                        drugLog.medicineList = medicineSet;
                        self.recordLog.drugLog = drugLog;
                        
                        break;
                    }
                    case RecoveryLogStatusAdd:
                    {
                        RecordLog *recordLog = [RecordLog createEntityInContext:[CoreDataStack sharedCoreDataStack].context];
                        recordLog.id = [NSString stringWithFormat:@"%@",[responseData valueForKey:@"medicineId"]];
                        recordLog.logType = @"drug";
                        recordLog.time = dateTime;
                        
                        UserID *userID = [UserID createEntityInContext:[CoreDataStack sharedCoreDataStack].context];
                        userID.userId = [NSString userID];
                        userID.linkManId = [NSString linkmanID];
                        
                        DrugLog *drugLog = [DrugLog createEntityInContext:[CoreDataStack sharedCoreDataStack].context];
                        drugLog.medicineTime = dateTime;
                        drugLog.medicineId = recordLog.id;

                        recordLog.userid = userID;
                        drugLog.medicineList = medicineSet;
                        recordLog.drugLog = drugLog;
                        
                        break;
                    }
                }
                
                [[CoreDataStack sharedCoreDataStack] saveContext];
                double delayInSeconds = 1.35;
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self.navigationController popViewControllerAnimated:YES];
                });

            }else{
                aHud.labelText = [NSString localizedMsgFromRet_code:ret_code withHUD:YES];
            }
        }else{
            aHud.labelText = NSLocalizedString(@"Server is busy", nil);
        }
        
        [aHud hide:YES afterDelay:HUD_TIME_DELAY];
    }];
}

- (void)editDietLog
{
    MBProgressHUD *aHud = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
    [self.navigationController.view addSubview:aHud];
    aHud.labelText = NSLocalizedString(@"Saving Data", nil);
    [aHud show:YES];
    
    NSString *dateTime = [NSString stringWithFormat:@"%@ %@",self.date,self.time];
    dateTime = [NSString formattingDateString:dateTime From:@"yyyy-MM-dd HH:mm" to:@"yyyyMMddHHmmss"];
    NSString *eatPeriod = [NSString formattingDietPeriod:self.period];
    
    NSMutableArray *foodList = [[NSMutableArray alloc] initWithCapacity:10];
    NSMutableOrderedSet *foodSet = [[NSMutableOrderedSet alloc] initWithCapacity:10];
    __block CGFloat calorie;
    [self.dietArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        Food *food = (Food *)obj;
        if (!food.calorie || !food.food || !food.sort || !food.unit || !food.weight) {
            return ;
        }
 
        if (food.weight) {
            NSDictionary *foodDic = @{@"calorie":[NSNumber numberWithFloat:food.calorie.floatValue],
                                      @"food":food.food,
                                      @"sort":food.sort,
                                      @"unit":food.unit,
                                      @"weight":food.weight};
            
            calorie += food.calorie.floatValue;
            [foodList addObject:foodDic];
            [foodSet addObject:food];
        }
        
    }];
    NSString *sumCalorie = [NSString stringWithFormat:@"%.f",calorie];
    NSString *jsonString = [foodList JSONString];
    
    __block NSMutableDictionary *parameters = [@{@"method":@"dietLogEdit",
                                                 @"sign":@"sign",
                                                 @"sessionId":[NSString sessionID],
                                                 @"linkManId":[NSString linkmanID],
                                                 @"calorie":sumCalorie?sumCalorie :@"",
                                                 @"eatPeriod":eatPeriod ? eatPeriod :@"",
                                                 @"eatTime":dateTime ? dateTime : @"",
                                                 @"foodList":jsonString ? jsonString : @"",
                                                 } mutableCopy];
    
    switch (self.recoveryLogStatus) {
        case RecoveryLogStatusEdit:
        {
            [parameters setValue:self.recordLog.dietLog.eatId forKey:@"eatId"];
            break;
        }
        case RecoveryLogStatusAdd:
            break;
    }
    
    [GCRequest userEditDietLogWithParameters:parameters withBlock:^(NSDictionary *responseData, NSError *error) {
        aHud.mode = MBProgressHUDModeText;
        if (!error) {
            NSString *ret_code = [responseData valueForKey:@"ret_code"];
            if ([ret_code isEqualToString:@"0"]) {
                aHud.labelText = NSLocalizedString(@"Data Updated", nil);
                
                switch (self.recoveryLogStatus) {
                    case RecoveryLogStatusEdit:
                    {
                        DietLog *dietLog = self.recordLog.dietLog;
                        dietLog.calorie = [NSString stringWithFormat:@"%.1f",calorie];
                        dietLog.eatPeriod = self.period;
                        dietLog.eatTime = dateTime;
                        dietLog.foodList = foodSet;
                        
                        
                        self.recordLog.time = dateTime;
                        self.recordLog.dietLog = dietLog;
                        
                        break;
                    }
                    case RecoveryLogStatusAdd:
                    {
                        RecordLog *recordLog = [RecordLog createEntityInContext:[CoreDataStack sharedCoreDataStack].context];
                        
                        UserID *userID = [UserID createEntityInContext:[CoreDataStack sharedCoreDataStack].context];
                        userID.userId = [NSString userID];
                        userID.linkManId = [NSString linkmanID];
                        
                        DietLog *dietLog = [DietLog createEntityInContext:[CoreDataStack sharedCoreDataStack].context];
                        dietLog.eatId = [NSString stringWithFormat:@"%@",[responseData valueForKey:@"eatId"]];
                        dietLog.calorie = [NSString stringWithFormat:@"%.1f",calorie];
                        dietLog.eatPeriod = self.period;
                        dietLog.eatTime = dateTime;
                        dietLog.foodList = foodSet;;
                        
                        
                        recordLog.userid = userID;
                        recordLog.dietLog = dietLog;
                        recordLog.logType = @"diet";
                        recordLog.time = dateTime;
                        recordLog.id = dietLog.eatId;
            
                        break;
                    }
                }
                
                [[CoreDataStack sharedCoreDataStack] saveContext];
                double delayInSeconds = 1.35;
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self.navigationController popViewControllerAnimated:YES];
                });
                
            }else{
                aHud.labelText = [NSString localizedMsgFromRet_code:ret_code withHUD:YES];
            }
        }else{
            aHud.labelText = NSLocalizedString(@"Server is busy", nil);
        }
        
        [aHud hide:YES afterDelay:HUD_TIME_DELAY];
    }];
    
}

- (void)editExerciseLog
{
    MBProgressHUD *aHud = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
    [self.navigationController.view addSubview:aHud];
    aHud.labelText = NSLocalizedString(@"Saving Data", nil);
    [aHud show:YES];
    
    ExerciseCell *exerciseCell = (ExerciseCell *)[self.exerciseView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:1]];
    
    NSString *dateTime = [NSString stringWithFormat:@"%@ %@",self.date,self.time];
    dateTime = [NSString formattingDateString:dateTime From:@"yyyy-MM-dd HH:mm" to:@"yyyyMMddHHmmss"];
    
    NSMutableDictionary *parameters = [@{@"method":@"exerciseLogEdit",
                                         @"sign":@"sign",
                                         @"sessionId":[NSString sessionID],
                                         @"linkManId":[NSString linkmanID],
                                         @"calorie":exerciseCell.calorie.text,
                                         @"duration":exerciseCell.time.text,
                                         @"sportName":exerciseCell.exerciseName.text,
                                         @"sportTime":dateTime ? dateTime : @"",
                                         } mutableCopy];
    
    switch (self.recoveryLogStatus) {
        case RecoveryLogStatusEdit:
        {
            [parameters setValue:self.recordLog.exerciseLog.sportId forKey:@"sportId"];
            break;
        }
        case RecoveryLogStatusAdd:
            break;
    }
    
    [GCRequest userEditExerciseLogWithParameters:parameters withBlock:^(NSDictionary *responseData, NSError *error) {
        aHud.mode = MBProgressHUDModeText;
        if (!error) {
            NSString *ret_code = [responseData valueForKey:@"ret_code"];
            if ([ret_code isEqualToString:@"0"]) {
                aHud.labelText = NSLocalizedString(@"Data Updated", nil);
                
                switch (self.recoveryLogStatus) {
                    case RecoveryLogStatusEdit:
                    {
                        ExerciseLog *exerciseLog;
                        exerciseLog = self.recordLog.exerciseLog;
  
                        [exerciseLog updateCoreDataForData:parameters withKeyPath:nil];
                        
                        self.recordLog.time = dateTime;
                        self.recordLog.exerciseLog = exerciseLog;
                        break;
                    }
                    case RecoveryLogStatusAdd:
                    {
                        RecordLog *recordLog = [RecordLog createEntityInContext:[CoreDataStack sharedCoreDataStack].context];
                        recordLog.logType = @"exercise";
                        recordLog.time = dateTime ;
                        recordLog.id = [NSString stringWithFormat:@"%@",[responseData valueForKey:@"sportId"]];
                        
                        UserID *userId = [UserID createEntityInContext:[CoreDataStack sharedCoreDataStack].context];
                        userId.userId = [NSString userID];
                        userId.linkManId = [NSString linkmanID];
                        
                        ExerciseLog *exerciseLog = [ExerciseLog createEntityInContext:[CoreDataStack sharedCoreDataStack].context];
                        [exerciseLog updateCoreDataForData:parameters withKeyPath:nil];
                        exerciseLog.sportId = recordLog.id;
                        
                        recordLog.userid = userId;
                        recordLog.exerciseLog = exerciseLog;
                        break;
                    }
                }
                
                [[CoreDataStack sharedCoreDataStack] saveContext];
                
                double delayInSeconds = 1.35;
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self.navigationController popViewControllerAnimated:YES];
                });

            }else{
                aHud.labelText = [NSString localizedMsgFromRet_code:ret_code withHUD:YES];
            }
        }else{
            aHud.labelText = NSLocalizedString(@"Server is busy", nil);
        }
        [aHud hide:YES afterDelay:HUD_TIME_DELAY];
    }];
    
}
- (void)registerCellAndSectionHeaderViewForTableView
{
    // Cell Registeration
    
    if (self.detectView) {
        [self.detectView registerNib:[UINib nibWithNibName:@"BasicCell" bundle:nil] forCellReuseIdentifier:BasicCellIdentifier];
        [self.detectView registerNib:[UINib nibWithNibName:@"FeelingCell" bundle:nil] forCellReuseIdentifier:FeelingCellIdentifier];
        [self.detectView registerNib:[UINib nibWithNibName:@"DetectCell" bundle:nil] forCellReuseIdentifier:DetectCellIdentifier];
        [self.detectView registerNib:[UINib nibWithNibName:@"LogSectionHeaderView" bundle:nil] forHeaderFooterViewReuseIdentifier:SectionHeaderViewIdentifier];

    }
    
    if (self.drugView) {
        [self.drugView registerNib:[UINib nibWithNibName:@"BasicCell" bundle:nil] forCellReuseIdentifier:BasicCellIdentifier];
        [self.drugView registerNib:[UINib nibWithNibName:@"MedicateCell" bundle:nil] forCellReuseIdentifier:MediacteCellIdentifier];
        [self.drugView registerNib:[UINib nibWithNibName:@"LogSectionHeaderView" bundle:nil] forHeaderFooterViewReuseIdentifier:SectionHeaderViewIdentifier];

    }
    
    if (self.dietView) {
        [self.dietView registerNib:[UINib nibWithNibName:@"BasicCell" bundle:nil] forCellReuseIdentifier:BasicCellIdentifier];
        [self.dietView registerNib:[UINib nibWithNibName:@"DietCell" bundle:nil] forCellReuseIdentifier:DietCellIdentifier];
        [self.dietView registerNib:[UINib nibWithNibName:@"LogSectionHeaderView" bundle:nil] forHeaderFooterViewReuseIdentifier:SectionHeaderViewIdentifier];

    }
    
    if (self.exerciseView) {
        [self.exerciseView registerNib:[UINib nibWithNibName:@"BasicCell" bundle:nil] forCellReuseIdentifier:BasicCellIdentifier];
        [self.exerciseView registerNib:[UINib nibWithNibName:@"ExerciseCell" bundle:nil] forCellReuseIdentifier:ExerciseCellIndentifier];
        [self.exerciseView registerNib:[UINib nibWithNibName:@"LogSectionHeaderView" bundle:nil] forHeaderFooterViewReuseIdentifier:SectionHeaderViewIdentifier];

    }
    
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
    UITableView *itemView;
    NSInteger statusExpression;
    if (self.recoveryLogStatus == RecoveryLogStatusAdd) {
        statusExpression = index;
    }else{
        statusExpression = self.recoveryLogType;
    }
    
    switch (statusExpression) {
        case RecoveryLogTypeDetect:
            self.recoveryLogType = RecoveryLogTypeDetect;

            if (!self.detectView) {
                self.detectView = [[NSBundle mainBundle] loadNibNamed:@"detect" owner:self options:nil][0];
                self.detectView.tag = RecoveryLogTypeDetect;
                self.detectView.delegate = self;
                self.detectView.dataSource = self;
                [self dataSetup];


            }
            itemView = self.detectView;
            break;
            
        case RecoveryLogTypeDrug:
            self.recoveryLogType = RecoveryLogTypeDrug;

            if (!self.drugView) {
                self.drugView = [[NSBundle mainBundle] loadNibNamed:@"drug" owner:self options:nil][0];
                self.drugView.tag = RecoveryLogTypeDrug;
                self.drugView.delegate = self;
                self.drugView.dataSource = self;
                [self dataSetup];
            }
            itemView  = self.drugView;
            break;
            
        case RecoveryLogTypeDiet:
            self.recoveryLogType = RecoveryLogTypeDiet;

            if (!self.dietView) {
                self.dietView = [[NSBundle mainBundle] loadNibNamed:@"diet" owner:self options:nil][0];
                self.dietView.tag = RecoveryLogTypeDiet;
                self.dietView.delegate = self;
                self.dietView.dataSource = self;
                [self dataSetup];

            }
            itemView = self.dietView;
            break;
        case RecoveryLogTypeExercise:
            self.recoveryLogType = RecoveryLogTypeExercise;

            if (!self.exerciseView) {
                self.exerciseView = [[NSBundle mainBundle] loadNibNamed:@"exercise" owner:self options:nil][0];
                self.exerciseView.tag = RecoveryLogTypeExercise;
                self.exerciseView.delegate = self;
                self.exerciseView.dataSource = self;
                [self dataSetup];

            }
            itemView = self.exerciseView;
            break;
    }


    [self registerCellAndSectionHeaderViewForTableView];
    
    UIView *helperView = [UIView new];
    helperView.backgroundColor = [UIColor clearColor];
    [itemView setTableFooterView:helperView];
    
    

    return itemView;
    
}

- (CGSize)swipeViewItemSize:(SwipeView *)swipeView
{
    return swipeView.bounds.size;
}

- (void)swipeViewDidEndDecelerating:(SwipeView *)swipeView
{
    self.tabBar.selectedItem = [self.tabBar.items objectAtIndex:swipeView.currentItemIndex];
    self.recoveryLogType = swipeView.currentItemIndex;
}

#pragma mark - TableViewDelegate/DataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    switch (tableView.tag) {
        case RecoveryLogTypeDetect:
            return 2;
        case RecoveryLogTypeDrug:
            return 4;
        case RecoveryLogTypeDiet:
            return 2;
        case RecoveryLogTypeExercise:
            return 2;

    }
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger count = 0;
    switch (tableView.tag) {
        case RecoveryLogTypeDetect:
            switch (section) {
                case 0:
                    count = 5;
                    break;
                case 1:
                    count = 3;
                    break;
                default:
                    break;
            }
            break;
        case RecoveryLogTypeDrug:
            switch (section) {
                case 0:
                    count = 2;
                    break;
                case 1:
                    count = self.insulinArray.count+1;
                    break;
                case 2:
                    count = self.drugsArray.count+1;
                    break;
                case 3:
                    count = self.othersArray.count+1;
                    break;
            }
            break;
        case RecoveryLogTypeDiet:
            if (section == 0) {
                count =  3;
            } else {
                count = self.dietArray.count+1;
            };
            break;
        case RecoveryLogTypeExercise:
            if (section == 0) {
                count = 2;
            } else {
                count = 2;
            }
            break;
    }
    return count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == 0) {
        return 10;
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
        case RecoveryLogTypeDetect:
            if (section == 1) {
                headerView.titleLabel.text = NSLocalizedString(@"检测结果",nil);
                headerView.addBtn.hidden = YES;
            }
            break;
        case RecoveryLogTypeDrug:
            if (section == 1) {
                headerView.titleLabel.text = NSLocalizedString(@"胰岛素", nil);
            }
            if (section == 2) {
                headerView.titleLabel.text = NSLocalizedString(@"降糖药", nil);
            }
            if (section == 3) {
                headerView.titleLabel.text = NSLocalizedString(@"其他", nil);
            }
            break;
        case RecoveryLogTypeDiet:
            if (section == 1) {
                headerView.titleLabel.text = NSLocalizedString(@"摄入食物", nil);
            }
            break;
        case RecoveryLogTypeExercise:
            if (section == 1) {
                headerView.titleLabel.text = NSLocalizedString(@"运动数据", nil);
                headerView.addBtn.hidden = YES;
            }
            break;
        default:
            break;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat cellHeight;
    cellHeight = 44;
    return cellHeight;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    switch (tableView.tag) {
            
        case RecoveryLogTypeDetect:
        {
            if (indexPath.section == 0) {
                
                if (indexPath.row == 3) {
                    FeelingCell *cell = [tableView dequeueReusableCellWithIdentifier:FeelingCellIdentifier forIndexPath:indexPath];
                    [self configureTableView:tableView withFeelingCell:cell atIndexPath:indexPath];
                    return cell;
                }
                    BasicCell *cell = [tableView dequeueReusableCellWithIdentifier:BasicCellIdentifier forIndexPath:indexPath];
                    [self configureTableView:tableView withBasicCell:cell atIndexPath:indexPath];
                    return cell;

            }
            else{
                DetectCell *cell = [tableView dequeueReusableCellWithIdentifier:DetectCellIdentifier forIndexPath:indexPath];
                [self configureTableView:tableView withDetectCell:cell atIndexPath:indexPath];
                return cell;
            }
            
            break;
        }

        case RecoveryLogTypeDrug:
        {
            if (indexPath.section == 0) {
                BasicCell *cell = [tableView dequeueReusableCellWithIdentifier:BasicCellIdentifier forIndexPath:indexPath];
                [self configureTableView:tableView withBasicCell:cell atIndexPath:indexPath];
                return cell;
            }
            else {
                MedicateCell *cell = [tableView dequeueReusableCellWithIdentifier:MediacteCellIdentifier forIndexPath:indexPath];
                [self configureTableView:tableView withMedicateCell:cell atIndexPath:indexPath];
                return cell;
                
            }

            break;
        }
            
        case RecoveryLogTypeDiet:
        {
            switch (indexPath.section) {
                case 0:
                {
                    BasicCell *cell = [tableView dequeueReusableCellWithIdentifier:BasicCellIdentifier forIndexPath:indexPath];
                    [self configureTableView:tableView withBasicCell:cell atIndexPath:indexPath];
                    return cell;
                    break;
                }
                    
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
            
        case RecoveryLogTypeExercise:
        {
            switch (indexPath.section) {
                    
                case 0:
                {
                    BasicCell *cell = [tableView dequeueReusableCellWithIdentifier:BasicCellIdentifier forIndexPath:indexPath];
                    [self configureTableView:tableView withBasicCell:cell atIndexPath:indexPath];
                    return cell;
                    break;
                }
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

- (void)configureTableView:(UITableView *)tableView withFeelingCell:(FeelingCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.title.text = NSLocalizedString(@"自我感觉", nil);
    cell.selectedArray = self.feelingArray;
    [cell initialSelectedBtn];
    cell.selectedFeelingBlock = ^void (NSMutableArray *selecteArray){
        self.feelingArray = selecteArray;
    };
}

- (void)configureTableView:(UITableView *)tableView withDetectCell:(DetectCell *)cell atIndexPath:(NSIndexPath *)indexPath
{

    if (indexPath.row == 0) {
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.detectType.text = NSLocalizedString(@"检测类型", nil);
        cell.detectField.text = NSLocalizedString(@"检测值", nil);
        cell.detectUnit.text = NSLocalizedString(@"单位", nil);
    }
                
    if (indexPath.row == 1) {
        if ([self.recordLog.detectLog.dataSource isEqualToString:@"01"]) {
            cell.detectField.userInteractionEnabled = NO;
        }else{
            cell.detectField.userInteractionEnabled = YES;
        }
        cell.detectField.logFieldIdentify = @"glucose";
        cell.detectField.logIndexPath = indexPath;
        cell.detectField.delegate = self;
        cell.detectType.text = NSLocalizedString(@"glucose", nil);
        cell.detectUnit.text = NSLocalizedString(@"mmol/L", nil);
        cell.detectField.text = self.recordLog.detectLog.glucose;
        self.gluco = cell.detectField.text;
        cell.detectField.placeholder = NSLocalizedString(@"Input Detect Value", nil);
    }
    if (indexPath.row == 2) {
        if ([self.recordLog.detectLog.dataSource isEqualToString:@"01"]) {
            cell.detectField.userInteractionEnabled = NO;
        }else{
            cell.detectField.userInteractionEnabled = YES;
        }
        cell.detectField.logFieldIdentify = @"hemoglobinef";
        cell.detectField.logIndexPath = indexPath;
        cell.detectField.delegate = self;
        cell.detectType.text = NSLocalizedString(@"hemoglobin", nil);
        cell.detectUnit.text = NSLocalizedString(@"%", nil);
        cell.detectField.text = self.recordLog.detectLog.hemoglobinef;
        self.hemo = cell.detectField.text;
        cell.detectField.placeholder = NSLocalizedString(@"Input Detect Value", nil);
    }

            
}

- (void)configureTableView:(UITableView *)tableView withMedicateCell:(MedicateCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    if (!indexPath.row == 0) {
        cell.drugField.placeholder = NSLocalizedString(@"药品名称", nil);
        cell.usageField.placeholder = NSLocalizedString(@"用法", nil);
        cell.dosageField.placeholder = NSLocalizedString(@"用量", nil);
        cell.unitField.placeholder = NSLocalizedString(@"单位", nil);
        
        cell.dosageField.userInteractionEnabled = YES;
        cell.dosageField.delegate = self;
        cell.dosageField.logIndexPath = indexPath;
        cell.dosageField.logFieldIdentify = @"dosage";
        
        Medicine *medicine;
        
        switch (indexPath.section) {
            case 1:
                medicine = self.insulinArray[indexPath.row-1];
                cell.drugField.userInteractionEnabled = NO;
                break;
            case 2:
                medicine = self.drugsArray[indexPath.row-1];
                cell.drugField.userInteractionEnabled = NO;
                break;
            case 3:
                medicine = self.othersArray[indexPath.row-1];
                cell.drugField.userInteractionEnabled = YES;
                cell.drugField.delegate = self;
                cell.drugField.logIndexPath = indexPath;
                cell.drugField.logFieldIdentify = @"drug";

                break;
        }
        
        if ([medicine isKindOfClass:[Medicine class]]) {
            cell.drugField.text = medicine.drug;
            cell.usageField.text = medicine.usage;
            cell.dosageField.text = medicine.dose;
            cell.unitField.text = medicine.unit;
        }
        
    }else{
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        cell.drugField.text = NSLocalizedString(@"药品名称", nil);
        cell.usageField.text = NSLocalizedString(@"用法", nil);
        cell.dosageField.text = NSLocalizedString(@"用量", nil);
        cell.unitField.text = NSLocalizedString(@"单位", nil);
    }
    
    
}

- (void)configureTableView:(UITableView *)tableView withDietCell:(DietCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    if (!indexPath.row == 0) {
        
        cell.food.placeholder = NSLocalizedString(@"食物名称", nil);
        cell.weight.placeholder = NSLocalizedString(@"摄入量", nil);
        cell.unit.placeholder = NSLocalizedString(@"单位", nil);
        cell.calorie.placeholder = NSLocalizedString(@"摄入卡路里", nil);
        
        cell.weight.delegate = self;
        cell.weight.logIndexPath = indexPath;
        cell.weight.logFieldIdentify = @"weight";
        cell.weight.userInteractionEnabled = YES;
        
        cell.calorie.delegate = self;
        cell.calorie.logIndexPath = indexPath;
        cell.calorie.logFieldIdentify = @"calorie";
        cell.calorie.userInteractionEnabled = YES;
        
        Food *food;
        food = self.dietArray[indexPath.row-1];
        
        if ([food isKindOfClass:[food class]]) {
            cell.food.text = food.food;
            cell.weight.text = food.weight;
            cell.unit.text = food.unit;
            cell.calorie.text = food.calorie ? [NSString stringWithFormat:@"%.f",food.calorie.floatValue]: food.calorie ;
        }
    }else{
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.food.text = NSLocalizedString(@"食物名称", nil);
        cell.weight.text = NSLocalizedString(@"摄入量", nil);
        cell.unit.text = NSLocalizedString(@"单位", nil);
        cell.calorie.text = NSLocalizedString(@"摄入卡路里", nil);
    }
   
}

- (void)configureTableView:(UITableView *)tableView withExerciseCell:(ExerciseCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 1) {
        
        cell.exerciseName.placeholder = NSLocalizedString(@"输入名称", nil);
        cell.time.placeholder = NSLocalizedString(@"输入时长", nil);
        cell.unit.placeholder = NSLocalizedString(@"单位", nil);
        cell.calorie.placeholder = NSLocalizedString(@"消耗卡路里", nil);
        
        cell.time.delegate = self;
        cell.time.logIndexPath = indexPath;
        cell.time.logFieldIdentify = @"time";
        cell.time.userInteractionEnabled = YES;
        
        cell.calorie.delegate = self;
        cell.calorie.logIndexPath = indexPath;
        cell.calorie.logFieldIdentify = @"exerciseCalorie";
        cell.calorie.userInteractionEnabled = YES;

        
        if (self.recordLog) {
            cell.exerciseName.text = self.recordLog.exerciseLog.sportName;
            cell.time.text = self.recordLog.exerciseLog.duration;
            cell.unit.text = NSLocalizedString(@"min", nil);
            cell.calorie.text = self.recordLog.exerciseLog.calorie ? [NSString stringWithFormat:@"%.f",self.recordLog.exerciseLog.calorie.floatValue]: nil;
        }
        
    }else{
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.exerciseName.text = NSLocalizedString(@"运动项目", nil);
        cell.time.text = NSLocalizedString(@"时长", nil);
        cell.unit.text = NSLocalizedString(@"单位", nil);
        cell.calorie.text = NSLocalizedString(@"消耗卡路里", nil);
    }
    
}

- (void)configureTableView:(UITableView *)tableView withBasicCell:(BasicCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    
    NSString *dateString = [NSString formattingDateString:self.recordLog.time From:@"yyyyMMddHHmmss" to:@"yyyy-MM-dd"];
    NSString *timeString = [NSString formattingDateString:self.recordLog.time From:@"yyyyMMddHHmmss" to:@"HH:mm"];
    
    if (!dateString || !timeString) {
        NSDate *nowDate = [NSDate date];
        dateString  = [NSString formattingDate:nowDate to:@"yyyy-MM-dd"];
        timeString = [NSString formattingDate:nowDate to:@"HH:mm"];
    }
    
    switch (tableView.tag) {
            
        case RecoveryLogTypeDetect:
            
            if ([self.recordLog.detectLog.dataSource isEqualToString:@"01"]) {
                cell.userInteractionEnabled = NO;
            }
            
            switch (indexPath.row) {
                case 0:
                    cell.selectionStyle = UITableViewCellSelectionStyleNone;
                    cell.title.text = NSLocalizedString(@"检测设备",nil);
                    if ([self.recordLog.detectLog.dataSource isEqualToString:@"01"]) {
                        cell.detailText.text = NSLocalizedString(@"GlucoTrack", nil);
                    }else{
                        cell.detailText.text = NSLocalizedString(@"其他", nil);
                    }
                    break;
                case 1:
                {
                    cell.title.text = NSLocalizedString(@"检测日期",nil);
                    cell.detailText.placeholder = NSLocalizedString(@"选择日期", nil);
                    cell.detailText.text = dateString;
                    self.date = dateString;
                    break;
                }
                case 2:
                {
                    cell.title.text = NSLocalizedString(@"检测时间", nil);
                    cell.detailText.placeholder = NSLocalizedString(@"选择时间",nil);
                    cell.detailText.text = timeString;
                    self.time = timeString;
                    break;
                }
                case 4:
                    cell.selectionStyle = UITableViewCellSelectionStyleNone;
                    cell.userInteractionEnabled = YES;
                    cell.detailText.delegate = self;
                    cell.detailText.logIndexPath = indexPath;
                    cell.detailText.logFieldIdentify = @"remark";
                    cell.title.text = NSLocalizedString(@"增加备注", nil);
                    cell.detailText.placeholder = NSLocalizedString(@"可选", nil);
                    cell.detailText.text = self.recordLog.detectLog.remar;
                    self.remark = self.recordLog.detectLog.remar;
                    cell.detailText.enabled = YES;
                    break;
                default:
                    break;
            }
            break;
        case RecoveryLogTypeDrug:
            switch (indexPath.row) {
                case 0:
                    cell.title.text = NSLocalizedString(@"用药日期",nil);
                    cell.detailText.placeholder = NSLocalizedString(@"选择日期", nil);
                    cell.detailText.text = dateString;
                    self.date = dateString;
                    break;
                case 1:
                    cell.title.text = NSLocalizedString(@"用药时间", nil);
                    cell.detailText.placeholder = NSLocalizedString(@"选择时间",nil);
                    cell.detailText.text = timeString;
                    self.time = timeString;
                    break;
                default:
                    break;
            }
            break;
        case RecoveryLogTypeDiet:
            switch (indexPath.row) {
                case 0:
                    cell.title.text = NSLocalizedString(@"饮食日期",nil);
                    cell.detailText.placeholder = NSLocalizedString(@"选择日期", nil);
                    cell.detailText.text = dateString;
                    self.date = dateString;
                    break;
                case 1:
                    cell.title.text = NSLocalizedString(@"饮食时间", nil);
                    cell.detailText.placeholder = NSLocalizedString(@"选择时间",nil);
                    cell.detailText.text = timeString;
                    self.time = timeString;
                    break;
                case 2:
                    cell.title.text = NSLocalizedString(@"三餐情况", nil);
                    cell.detailText.text = self.recordLog.dietLog.eatPeriod;
                    self.period = self.recordLog.dietLog.eatPeriod;
                    cell.detailText.placeholder = NSLocalizedString(@"选择用餐时间", nil);
                    break;
                default:
                    break;
            }
            break;
        case RecoveryLogTypeExercise:
            switch (indexPath.row) {
                case 0:
                    cell.title.text = NSLocalizedString(@"运动日期",nil);
                    cell.detailText.placeholder = NSLocalizedString(@"选择日期", nil);
                    cell.detailText.text = dateString;
                    self.date = dateString;
                    break;
                case 1:
                    cell.title.text = NSLocalizedString(@"开始时间", nil);
                    cell.detailText.placeholder = NSLocalizedString(@"选择时间",nil);
                    cell.detailText.text = timeString;
                    self.time = timeString;
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
    
    switch (tableView.tag) {
        case RecoveryLogTypeDetect:
            switch (indexPath.section) {
                case 0:
                    switch (indexPath.row) {
                        case 0:
                            break;
                        case 1:
                            [self showDatePickerHUDWithMode:UIDatePickerModeDate];
                            break;
                        case 2:
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

                    
                default:
                    break;
            }
            
            break;
        case RecoveryLogTypeDrug:
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
                case 3:
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
            
        case RecoveryLogTypeDiet:
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
                            self.sheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"选择用餐类型",nil) delegate:self cancelButtonTitle:nil destructiveButtonTitle:@"取消" otherButtonTitles:
                                          NSLocalizedString(@"早餐", nil) ,
                                          NSLocalizedString(@"午餐",nil),
                                          NSLocalizedString(@"晚餐",nil),
                                          NSLocalizedString(@"加餐",nil),nil];
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
                    [self.pickerView selectRow:0 inComponent:0 animated:NO];
                    [self.pickerView reloadAllComponents];
                    break;
                    
                default:
                    break;
            }
            break;
        
        case RecoveryLogTypeExercise:
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

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView.tag == RecoveryLogTypeDetect || tableView.tag == RecoveryLogTypeExercise || indexPath.section == 0 || indexPath.row == 0) {
        return NO;
    }
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        if ([cell isKindOfClass:[MedicateCell class]]){
            switch (indexPath.section) {
                case 1:
                    [self.insulinArray removeObjectAtIndex:indexPath.row-1];
                    [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
                    break;
                case 2:
                    [self.drugsArray removeObjectAtIndex:indexPath.row-1];
                    [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationRight];
                    break;
                case 3:
                    [self.othersArray removeObjectAtIndex:indexPath.row-1];
                    [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                    break;
                default:
                    break;
            }
        }else if ([cell isKindOfClass:[DietCell class]]) {
            switch (indexPath.section) {
                case 1:
                    [self.dietArray removeObjectAtIndex:indexPath.row-1];
                    [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationLeft];
                    break;
                    
                default:
                    break;
            }
        }
    }
}



#pragma mark - LogSectionHeaderViewDelegate

- (void)LogSectionHeaderView:(LogSectionHeaderView *)headerView sectionToggleAdd:(NSInteger)section
{
    switch (self.recoveryLogType){
        case RecoveryLogTypeDrug:
            switch (headerView.section) {
                case 1:
                {
                    NSInteger insertRow = self.insulinArray.count + 1;
                    if ([self allowToAdd:insertRow]) {
                        NSIndexPath *insertIndexPath = [NSIndexPath indexPathForRow:insertRow inSection:headerView.section];
                        
                        Medicine *insertMedicine = [Medicine createEntityInContext:[CoreDataStack sharedCoreDataStack].context];
                        insertMedicine.sort = @"胰岛素";
                        
                        [self.insulinArray addObject:insertMedicine];
                        [self.drugView insertRowsAtIndexPaths:@[insertIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                    }
                    
                    break;
                }
                case 2:
                {
                    NSInteger insertRow = self.drugsArray.count + 1;
                    
                    if ([self allowToAdd:insertRow]) {
                        NSIndexPath *insertIndexPath = [NSIndexPath indexPathForRow:insertRow inSection:headerView.section];
                        
                        Medicine *insertMedicine = [Medicine createEntityInContext:[CoreDataStack sharedCoreDataStack].context];
                        insertMedicine.sort = @"降糖药";
                        
                        [self.drugsArray addObject:insertMedicine];
                        [self.drugView insertRowsAtIndexPaths:@[insertIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                    }
                    
                    break;
                }
                case 3:
                {
                    NSInteger insertRow = self.othersArray.count + 1;
                    if ([self allowToAdd:insertRow]) {
                        NSIndexPath *insertIndexPath = [NSIndexPath indexPathForRow:insertRow inSection:headerView.section];
                        
                        Medicine *insertMedicine = [Medicine createEntityInContext:[CoreDataStack sharedCoreDataStack].context];
                        insertMedicine.sort = @"其他";
                        
                        [self.othersArray addObject:insertMedicine];
                        [self.drugView insertRowsAtIndexPaths:@[insertIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                    }
    
                    break;
                }

            }
            
            break;

        case RecoveryLogTypeDiet:
            switch (headerView.section) {
                case 1:
                {
                    NSInteger insertRow = self.dietArray.count + 1;
                    if ([self allowToAdd:insertRow]) {
                        NSIndexPath *insertIndexPath = [NSIndexPath indexPathForRow:insertRow inSection:headerView.section];
                        Food *insertFood = [Food createEntityInContext:[CoreDataStack sharedCoreDataStack].context];
                        [self.dietArray addObject:insertFood];
                        [self.dietView insertRowsAtIndexPaths:@[insertIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                    }
                    
                    break;
                }
            }
            break;
        default:
            break;
    }

}

- (BOOL)allowToAdd:(NSInteger)insertRow
{
    if (insertRow-1 > 10) {
        MBProgressHUD *aHud = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
        [self.navigationController.view addSubview:aHud];
        aHud.mode = MBProgressHUDModeText;
        aHud.labelText = NSLocalizedString(@"Not to Add More", nil);
        [aHud show:YES];
        [aHud hide:YES afterDelay:HUD_TIME_DELAY];
        return NO;
    }else{
        return YES;
    }
}

#pragma mark - DatePickerHUD

- (void)showDatePickerHUDWithMode:(UIDatePickerMode )mode
{
    hud = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
    [self.navigationController.view addSubview:hud];
    
    hud.margin = 0;
    self.datePicker.datePickerMode = mode;
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
    UIButton *btn = (UIButton *)sender;
    switch (btn.tag) {
        case 1001:
        {
            
            switch (self.recoveryLogType) {
                case RecoveryLogTypeDetect:
                    break;
                case RecoveryLogTypeDrug:
                {
                    if (self.selectedIndexPath.section == 3) {
                        UILabel *usage = (UILabel *)[self.pickerView viewForRow:[self.pickerView selectedRowInComponent:0] forComponent:0];
                        UILabel *unit = (UILabel *)[self.pickerView viewForRow:[self.pickerView selectedRowInComponent:1] forComponent:1];
                        Medicine *medicine = self.othersArray[self.selectedIndexPath.row-1];
                        medicine.sort = @"其他";
                        medicine.unit = unit.text;
                        medicine.usage = usage.text;
                    }else{
                        
                        UILabel *drug = (UILabel*)[self.pickerView viewForRow:[self.pickerView selectedRowInComponent:0] forComponent:0];
                        UILabel *usage = (UILabel *)[self.pickerView viewForRow:[self.pickerView selectedRowInComponent:1] forComponent:1];
                        UILabel *unit = (UILabel *)[self.pickerView viewForRow:[self.pickerView selectedRowInComponent:2] forComponent:2];
                        
                        
                        Medicine *medicine;
                        if (self.selectedIndexPath.section == 1) {
                            medicine = self.insulinArray[self.selectedIndexPath.row-1];
                            medicine.sort = @"胰岛素";
                        }
                        if (self.selectedIndexPath.section == 2) {
                            medicine = self.drugsArray[self.selectedIndexPath.row-1];
                            medicine.sort = @"降糖药";
                        }
                        
                        medicine.unit = unit.text;
                        medicine.drug = drug.text;
                        medicine.usage = usage.text;
                        
                        
                        if ([medicine.drug isEqualToString:NSLocalizedString(@"Custom", nil)]) {
                            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"请输入药物名称", nil) message:nil delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) otherButtonTitles:NSLocalizedString(@"sure", nil), nil];
                            alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
                            
                            UITextField *tf = [alertView textFieldAtIndex:0];
                            tf.keyboardType = UIKeyboardTypeDefault;
                            
                            [alertView show];
                            [hud hide:YES];
                            return;

                        }
                    }
                   
                    
                    [self.drugView reloadRowsAtIndexPaths:@[self.selectedIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];

                    break;
                }
                case RecoveryLogTypeDiet:
                {
                    UILabel *category = (UILabel*)[self.pickerView viewForRow:[self.pickerView selectedRowInComponent:0] forComponent:0];
                    UILabel *foodName = (UILabel *)[self.pickerView viewForRow:[self.pickerView selectedRowInComponent:1] forComponent:1];
                    UILabel *unit = (UILabel *)[self.pickerView viewForRow:[self.pickerView selectedRowInComponent:2] forComponent:2];
                    
                    Food *food = self.dietArray[self.selectedIndexPath.row-1];
                    food.sort = category.text;
                    food.food = foodName.text;
                    food.weight = @"100";
                    food.unit = unit.text;

                    NSString *rate = [self.dietRate valueForKey:food.food];
                    food.calorie = [NSString stringWithFormat:@"%.1f",rate.floatValue * 100];
                    
                    if ([food.food isEqualToString:NSLocalizedString(@"Custom", nil)]) {
                        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"请输入食物名称", nil) message:nil delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) otherButtonTitles:NSLocalizedString(@"sure", nil), nil];
                        alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
                        
                        UITextField *tf = [alertView textFieldAtIndex:0];
                        tf.keyboardType = UIKeyboardTypeDefault;
                        [alertView show];
                        [hud hide:YES];
                        return;
                    }
                    
                    [self.dietView reloadRowsAtIndexPaths:@[self.selectedIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];

                    break;
                }
                case RecoveryLogTypeExercise:
                {
                    UILabel *sportName = (UILabel *)[self.pickerView viewForRow:[self.pickerView selectedRowInComponent:0] forComponent:0];
                    UILabel *time = (UILabel *)[self.pickerView viewForRow:[self.pickerView selectedRowInComponent:1] forComponent:1];
                    UILabel *unit = (UILabel *)[self.pickerView viewForRow:[self.pickerView selectedRowInComponent:2] forComponent:2];
                    
                    ExerciseCell *exerciseCell = (ExerciseCell *)[self.exerciseView cellForRowAtIndexPath:self.selectedIndexPath];
                    exerciseCell.exerciseName.text = sportName.text;
                    exerciseCell.time.text = time.text;
                    exerciseCell.unit.text = unit.text;
                    
                    NSString *rate = [self.exerciseRate valueForKey:sportName.text];
                    exerciseCell.calorie.text = [NSString stringWithFormat:@"%.f",rate.floatValue * time.text.integerValue];
                    
                    
                    
                    if ([sportName.text isEqualToString:NSLocalizedString(@"Custom", nil)]) {
                        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"请输入运动名称", nil) message:nil delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) otherButtonTitles:NSLocalizedString(@"sure", nil), nil];
                        alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
                        
                        UITextField *tf = [alertView textFieldAtIndex:0];
                        tf.keyboardType = UIKeyboardTypeDefault;
                        
                        [alertView show];
                        [hud hide:YES];
                        return;
                        
                    }
                    
                    break;
                }
            }
            
            break;
        }
        case 1000:
            break;
    }
    
    [hud hide:YES afterDelay:0.25];
}

#pragma mark - PickerViewDataSource/Delegate

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    NSInteger components = 0;

    switch (self.recoveryLogType) {

        case RecoveryLogTypeDrug:
            switch (self.selectedIndexPath.section) {
                case 1:
                case 2:
                    components = self.medicationData.count;
                    break;
                case 3:
                    components = 2;
                    break;
            }
            break;
        case RecoveryLogTypeDiet:
            switch (self.selectedIndexPath.section) {
                case 1:
                    components = 3;
                    break;
                    
                default:
                    break;
            }
            break;
        case RecoveryLogTypeExercise:
            switch (self.selectedIndexPath.section) {
                case 1:
                    components = self.exercisePickerData.count;
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
    switch (self.recoveryLogType) {

        case RecoveryLogTypeDrug:
            switch (self.selectedIndexPath.section) {
                case 1:
                    if (component == 0) {
                        rows = [self.medicationData[component][@"01"] count];
                    }else rows = [self.medicationData[component] count];
                    break;
                case 2:
                    if (component == 0) {
                        rows = [self.medicationData[component][@"02"] count];
                    }else rows = [self.medicationData[component] count];
                    break;
                case 3:
                    rows = [self.medicationData[component+1] count];
                    break;
            }
            break;
        case RecoveryLogTypeDiet:
            switch (self.selectedIndexPath.section) {
                case 1:
                    if (component == 0) {
                        rows = [self.dietData count];
                    }
                    if (component == 1) {
                        NSInteger row = [pickerView selectedRowInComponent:0];
                        rows = [[self.dietData[row] allValues][0] count];

                    }
                    if (component == 2) {
                        rows = 1;
                    }
    
                    break;
                    
                default:
                    break;
            }
            break;
        case RecoveryLogTypeExercise:
            switch (self.selectedIndexPath.section) {
                case 1:
                    rows = [self.exercisePickerData[component] count];
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
    titleLabel.font = [UIFont systemFontOfSize:14];
    titleLabel.textColor = [UIColor blackColor];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.adjustsFontSizeToFitWidth = YES;
    
    view = titleLabel;
 
    switch (self.recoveryLogType) {
            
        case RecoveryLogTypeDrug:
            switch (self.selectedIndexPath.section) {
                case 1:
                    if (component == 0) {
                        titleLabel.text = self.medicationData[component][@"01"][row];
                        if ([titleLabel.text isEqualToString:NSLocalizedString(@"Custom", nil)]) {
                            titleLabel.textColor = [UIColor orangeColor];
                        }
                    }
                    else titleLabel.text = self.medicationData[component][row];
                    break;
                case 2:
                    if (component == 0) {
                        titleLabel.text = self.medicationData[component][@"02"][row];
                        if ([titleLabel.text isEqualToString:NSLocalizedString(@"Custom", nil)]) {
                            titleLabel.textColor = [UIColor orangeColor];
                        }
                    }
                    else titleLabel.text = self.medicationData[component][row];
                    break;
                case 3:
                    titleLabel.text = self.medicationData[component+1][row];
                    break;
            }
            break;
        case RecoveryLogTypeDiet:
            switch (self.selectedIndexPath.section) {
                case 1:
                {
                    if (component == 0) {
                        titleLabel.text = [self.dietData[row] allKeys][0];
                    }
                    if (component == 1) {
                        NSInteger selectedRow = [pickerView selectedRowInComponent:0];
                        NSArray *foods = [self.dietData[selectedRow] allValues][0];
                        titleLabel.text = foods[row];
                        if ([titleLabel.text isEqualToString:NSLocalizedString(@"Custom", nil)]) {
                            titleLabel.textColor = [UIColor orangeColor];
                        }
                    }
                    
                    if (component == 2) {
                        if (row == 0) {
                            titleLabel.text = NSLocalizedString(@"g", nil);
                        }

                    }

                    break;
                }
                default:
                    break;
            }
            break;
        case RecoveryLogTypeExercise:
            switch (self.selectedIndexPath.section) {
                case 1:
                {
                    if (component == 0) {
                        titleLabel.text = self.exercisePickerData[component][row];
                        if ([titleLabel.text isEqualToString:NSLocalizedString(@"Custom", nil)]) {
                            titleLabel.textColor = [UIColor orangeColor];
                        }
                    }else{
                        titleLabel.text = self.exercisePickerData[component][row];
                    }
                    break;
                }
                default:
                    break;
            }
            break;
        default:
            break;
    }
    return titleLabel
    ;
    
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    switch (self.recoveryLogType) {
        case RecoveryLogTypeDiet:
        {
            switch (self.selectedIndexPath.section) {
                case 1:
                {
                    if (component == 0) {
                        [pickerView reloadComponent:1];
                    }
                    break;
                }
                default:
                    break;
            }
            break;
        }
        default:
            break;
    }
}

- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component
{
    CGFloat widthForComponent;
    if (component == 0) {
        widthForComponent = 140;
    }else widthForComponent = 70;
    return widthForComponent;
}

#pragma mark - AlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != 0) {
        
        UITextField *tf = [alertView textFieldAtIndex:0];
        if ([tf.text isEqualToString:@""]) {
            MBProgressHUD *aHud = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
            [self.navigationController.view addSubview:aHud];
            aHud.mode = MBProgressHUDModeText;
            aHud.labelText = NSLocalizedString(@"请输入药物名称", nil);
            [aHud show:YES];
            [aHud hide:YES afterDelay:HUD_TIME_DELAY];
            return;
        }
        
        switch (self.recoveryLogType) {
            case RecoveryLogTypeDetect:
                break;
            case RecoveryLogTypeDrug:
            {
                
                switch (self.selectedIndexPath.section) {
                    case 1:
                    {
                        Medicine *medicine = [self.insulinArray objectAtIndex:self.selectedIndexPath.row-1];
                        medicine.drug = tf.text;
                        
                        [self.insulinData addObject:tf.text];
                        [self.insulinData writeToFile:INSULIN_PATH atomically:YES];
                        break;
                    }
                    case 2:
                    {
                        Medicine *medicine = [self.drugsArray objectAtIndex:self.selectedIndexPath.row-1];
                        medicine.drug = tf.text;
                        
                        [self.drugData addObject:tf.text];
                        [self.drugData writeToFile:DRUGS_PATH atomically:YES];
                        break;
                    }
                    case 3:
                    {
                        break;
                    }
                    default:
                        break;
                }
                [self.drugView reloadRowsAtIndexPaths:@[self.selectedIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                break;
            }
            case RecoveryLogTypeDiet:
            {
                Food *food = [self.dietArray objectAtIndex:self.selectedIndexPath.row-1];
                food.food = tf.text;
                food.calorie = nil;
                
                [[[self.dietData lastObject] allValues][0] addObject:food.food];
                [self.dietData writeToFile:DIET_PATH atomically:YES];
                
                [self.dietView reloadRowsAtIndexPaths:@[self.selectedIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                break;
            }
            case RecoveryLogTypeExercise:
            {
                ExerciseCell *exerciseCell = (ExerciseCell *)[self.exerciseView cellForRowAtIndexPath:self.selectedIndexPath];
                exerciseCell.exerciseName.text = tf.text;
                
                [self.exerciseData addObject:tf.text];
                [self.exerciseData writeToFile:EXERCISE_PATH atomically:YES];
                
                break;
            }
        }
    }
}


#pragma mark - UITextFieldDelegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    BOOL fieldInput = YES;
    
    LogTextField *logField = (LogTextField *)textField;
    
    switch (self.recoveryLogType) {
        case RecoveryLogTypeDetect:
        {
            NSString *text = [[textField.text stringByAppendingString:string] substringWithRange:NSMakeRange(0, range.location+1-range.length)];
            
            if ([logField.logFieldIdentify isEqualToString:@"glucose"]) {
                fieldInput = [self filterDetectValue:text];
               
            }
            if ([logField.logFieldIdentify isEqualToString:@"hemoglobinef"]) {
                fieldInput = [self filterDetectValue:text];
            }
            break;
        }
        case RecoveryLogTypeDrug:
            if ([logField.logFieldIdentify isEqualToString:@"drug"]) {
                if ([self numberPredicateString:string]) {
                    if ([string isEqualToString:@""]) {
                        fieldInput = YES;
                    }else fieldInput = NO;

                }else fieldInput = YES;
            }
            if ([logField.logFieldIdentify isEqualToString:@"dosage"]) {
                if ([self numberPredicateString:string]) {
                    fieldInput = YES;
                }else fieldInput = NO;
            }
            break;
        case RecoveryLogTypeDiet:
        case RecoveryLogTypeExercise:
        {
            if ([self numberPredicateString:string]) {
                NSString *text = [[textField.text stringByAppendingString:string] substringWithRange:NSMakeRange(0, range.location+1-range.length)];

                if ([logField.logFieldIdentify isEqualToString:@"weight"]) {
                    
                    Food *food = self.dietArray[logField.logIndexPath.row-1];
                    food.weight = text;
                    NSString *rate = [self.dietRate valueForKey:food.food];
                    if (!rate) {
                        return YES;
                    }
                    food.calorie = [NSString stringWithFormat:@"%.f",rate.floatValue * text.floatValue];
                    DietCell *foodCell = (DietCell *)[self.dietView cellForRowAtIndexPath:logField.logIndexPath];
                    foodCell.calorie.text = food.calorie;
                }
                
                if ([logField.logFieldIdentify isEqualToString:@"calorie"]) {
                    Food *food = self.dietArray[logField.logIndexPath.row-1];
                    food.calorie = text;
                    NSString *rate = [self.dietRate valueForKey:food.food];
                    if (!rate) {
                        return YES;
                    }
                    food.weight = [NSString stringWithFormat:@"%.f",text.floatValue/rate.floatValue];
                    DietCell *foodCell = (DietCell *)[self.dietView cellForRowAtIndexPath:logField.logIndexPath];
                    foodCell.weight.text = food.weight;
                }
                    
                if ([logField.logFieldIdentify isEqualToString:@"time"]) {
                    
                    ExerciseCell *exerciseCell = (ExerciseCell *)[self.exerciseView cellForRowAtIndexPath:logField.logIndexPath];
                    NSString *rate = [self.exerciseRate valueForKey:exerciseCell.exerciseName.text];
                    if (!rate) {
                        return YES;
                    }
                    exerciseCell.calorie.text = [NSString stringWithFormat:@"%.f",rate.floatValue * text.floatValue];
                }
                
                if ([logField.logFieldIdentify isEqualToString:@"exerciseCalorie"]) {
                    ExerciseCell *exerciseCell = (ExerciseCell *)[self.exerciseView cellForRowAtIndexPath:logField.logIndexPath];
                    NSString *rate = [self.exerciseRate valueForKey:exerciseCell.exerciseName.text];
                    if (!rate) {
                        return YES;
                    }
                    exerciseCell.time.text = [NSString stringWithFormat:@"%.f",text.floatValue/rate.floatValue];
                }
                
                
                
                fieldInput = YES;
            }else{
                fieldInput = NO;
            }
        }
        default:
            break;
    }
    
    return fieldInput;
}

- (BOOL)filterDetectValue:(NSString *)text
{
    if (text.floatValue < 0.0f || text.floatValue > 12.0f) {
        MBProgressHUD *aHud = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
        [self.navigationController.view addSubview:aHud];
        aHud.mode = MBProgressHUDModeText;
        aHud.labelText = NSLocalizedString(@"检测值超过最大或最小值", nil);
        [aHud show:YES];
        [aHud hide:YES afterDelay:HUD_TIME_DELAY];
        return NO;
    }
    
    NSRange range = [text rangeOfString:@"."];
    if (range.location != NSNotFound) {
        if (range.location + 1 >= text.length-1) {
            if (range.location + 1 == text.length-1) {
                NSRange aRange;
                aRange.length = 1;
                aRange.location = range.location+1;
                if ([[text substringWithRange:aRange] isEqualToString:@"."]) {
                    return NO;
                }else return YES;
            }else return YES;
        }
        else return NO;
    }
    
    return YES;
}

- (BOOL)numberPredicateString:(NSString *)string
{
    NSCharacterSet *nonNumberSet = [[NSCharacterSet characterSetWithCharactersInString:NUMBERS] invertedSet];
    NSString *filter = [[string componentsSeparatedByCharactersInSet:nonNumberSet] componentsJoinedByString:@""];
    if ([string isEqualToString:filter] ) {
        return YES;
    }else{
        return NO;
    }
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    LogTextField *logField = (LogTextField *)textField;
    switch (self.recoveryLogType) {
        case RecoveryLogTypeDetect:
        {
            if ([logField.logFieldIdentify isEqualToString:@"remark"]) {
                self.remark = logField.text ? logField.text : @"";
            }
            if ([logField.logFieldIdentify isEqualToString:@"glucose"]) {
                self.gluco = logField.text ? logField.text : @"";
            }
            if ([logField.logFieldIdentify isEqualToString:@"hemoglobinef"]) {
                self.hemo = logField.text ? logField.text : @"";
            }
            break;
        }
        case RecoveryLogTypeDrug:
        {

            switch (logField.logIndexPath.section) {
                case 1:
                {
                    Medicine *medicine = self.insulinArray[logField.logIndexPath.row-1];
                    if ([logField.logFieldIdentify isEqualToString:@"dosage"]) {
                        medicine.dose = logField.text ? logField.text : @"";
                    }
                    break;
                }
                case 2:
                {
                    if ([logField.logFieldIdentify isEqualToString:@"dosage"]) {
                        Medicine *medicine = self.drugsArray[logField.logIndexPath.row-1];
                        medicine.dose = logField.text ? logField.text : @"";
                    }
                    
                    break;
                }
                case 3:
                {
                    Medicine *medicine = self.othersArray[logField.logIndexPath.row-1];
                    if ([logField.logFieldIdentify isEqualToString:@"dosage"]) {
                        medicine.dose = logField.text ? logField.text : @"";
                    }
                    if ([logField.logFieldIdentify isEqualToString:@"drug"]) {
                        medicine.drug = logField.text ? logField.text : @"";
                    }
                    
                    break;
                }
            }
            
            break;
        }
        default:
            break;
    }
    
}

#pragma mark - ActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != 0) {
        BasicCell *cell = (BasicCell *)[self.dietView cellForRowAtIndexPath:self.selectedIndexPath];
        cell.detailText.text = [actionSheet buttonTitleAtIndex:buttonIndex];
        self.period = cell.detailText.text;
    }

}

- (IBAction)datePickerBtnAction:(id)sender
{
    UIButton *btn = (UIButton *)sender;
    switch (btn.tag) {
        case 1000:
        {
            break;
        }
        case 1001:
        {
            if (![ParseData parseDateIsAvaliable:self.datePicker.date]) {
                [hud hide:YES];
                return;
            }
            
            NSString *dateString;
            if (self.datePicker.datePickerMode == UIDatePickerModeDate) {
                dateString = [NSString formattingDate:self.datePicker.date to:@"yyyy-MM-dd"];
                
                self.date = dateString;

            }else if (self.datePicker.datePickerMode == UIDatePickerModeTime){
                    dateString = [NSString formattingDate:self.datePicker.date to:@"HH:mm"];
                self.time = dateString;
            }
            
            BasicCell *cell;
            switch (self.recoveryLogType) {
                case RecoveryLogTypeDetect:
                    cell = (BasicCell *)[self.detectView cellForRowAtIndexPath:self.selectedIndexPath];
                    break;
                case RecoveryLogTypeDrug:
                    cell = (BasicCell *)[self.drugView cellForRowAtIndexPath:self.selectedIndexPath];
                    break;
                case RecoveryLogTypeDiet:
                    cell = (BasicCell *)[self.dietView cellForRowAtIndexPath:self.selectedIndexPath];
                    break;
                case RecoveryLogTypeExercise:
                    cell = (BasicCell *)[self.exerciseView cellForRowAtIndexPath:self.selectedIndexPath];
                    break;
                default:
                    break;
            }
            
            cell.detailText.text = dateString;
            
            break;
        }
    }
    
    [hud hide:YES afterDelay:0.25];
}



@end
