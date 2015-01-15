//
//  MedicalRecordViewController.m
//  SugarNursing
//
//  Created by Dan on 15-1-10.
//  Copyright (c) 2015年 Tisson. All rights reserved.
//

#import "MedicalRecordViewController.h"
#import "MedicalHistoryDetailCell.h"
#import "MedicalRecordEditViewController.h"
#import "PatientDataViewController.h"
#import "SectionHeaderView.h"
#import "UtilsMacro.h"
#import <SSPullToRefresh.h>


static NSString *SectionHeaderViewIdentifier = @"SectionHeaderViewIdentifier";
static NSString *TipsCellIdentifier = @"TipsCell";
static NSString *MedicalHistoryCellIndentifier = @"MedicalHistoryDetailCell";

@interface MedicalRecordViewController ()<UITableViewDataSource, UITableViewDelegate,NSFetchedResultsControllerDelegate,SectionHeaderViewDelegate,SSPullToRefreshViewDelegate>{
    MBProgressHUD *hud;
}

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (strong, nonatomic) NSFetchedResultsController *fetchController;
@property (strong, nonatomic) NSMutableArray *selectedArray;
@property (strong, nonatomic) SectionHeaderView *openSectionHeaderView;
@property (strong, nonatomic) SSPullToRefreshView *refreshView;


@end

#pragma mark -

#define HEADER_HEIGHT 48
#define SECTION_HEADER_HEIGHT 44

@implementation MedicalRecordViewController

- (void)awakeFromNib
{
    self.selectedArray = [[NSMutableArray alloc] initWithCapacity:10];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"Medical Record", nil);
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addMedicalData:)];
    
    [self configureFetchController];
    [self configureTableView];
    [self configureNoDataView];
    
}

- (void)viewDidLayoutSubviews
{
    if (self.refreshView == nil) {
        self.refreshView = [[SSPullToRefreshView alloc] initWithScrollView:self.tableView delegate:self];
        [self.refreshView startLoadingAndExpand:YES animated:YES];
    }
}

- (void)pullToRefreshViewDidStartLoading:(SSPullToRefreshView *)view
{
    [self getMedicalRecord];
}

- (void)configureFetchController
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"userid.userId=%@ && userid.linkManId=%@",[NSString userID],[NSString linkmanID]];
    self.fetchController = [MedicalRecord fetchAllGroupedBy:nil sortedBy:@"diagTime" ascending:YES withPredicate:predicate delegate:self incontext:[CoreDataStack sharedCoreDataStack].context];
    
}

- (void)configureTableView
{
    self.tableView.estimatedRowHeight = UITableViewAutomaticDimension;
    self.tableView.sectionHeaderHeight = SECTION_HEADER_HEIGHT;
    
    UINib *sectionHeaderNib = [UINib nibWithNibName:@"SectionHeaderView" bundle:nil];
    [self.tableView registerNib:sectionHeaderNib forHeaderFooterViewReuseIdentifier:SectionHeaderViewIdentifier];
    [self.tableView registerNib:[UINib nibWithNibName:@"TipsCell" bundle:nil]forCellReuseIdentifier:TipsCellIdentifier];
}

- (void)getMedicalRecord
{
    hud = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
    [self.navigationController.view addSubview:hud];
    hud.mode = MBProgressHUDModeText;
    
    NSDictionary *parameters = @{@"method":@"getMediRecordList",
                                 @"sign":@"sign",
                                 @"sessionId":[NSString sessionID],
                                 @"linkManId":[NSString linkmanID],
                                 };
    [GCRequest userGetMedicalRecordWithParameters:parameters withBlock:^(NSDictionary *responseData, NSError *error) {
        
        if (!error) {
            if ([[responseData valueForKey:@"ret_code"] isEqualToString:@"0"]) {
                
                // 先清除缓存
                for (MedicalRecord *record in self.fetchController.fetchedObjects) {
                    [record deleteEntityInContext:[CoreDataStack sharedCoreDataStack].context];
                }
                
                // 存入数据
                NSArray *records = [[responseData objectForKey:@"mediRecordList"] mutableCopy];
                for (NSDictionary *record in records) {
                    
                    NSMutableDictionary *mRecord = [record mutableCopy];
                    [mRecord dateFormattingToUser:@"yyyy-MM-dd" ForKey:@"diagTime"];
                    
                    MedicalRecord *medicalRecord = [MedicalRecord createEntityInContext:[CoreDataStack sharedCoreDataStack].context];
                    [medicalRecord updateCoreDataForData:mRecord withKeyPath:nil];
                    
                    UserID *userID = [UserID createEntityInContext:[CoreDataStack sharedCoreDataStack].context];
                    userID.userId = [NSString userID];
                    userID.linkManId = [NSString linkmanID];
                    
                    medicalRecord.userid = userID;
                }
                [[CoreDataStack sharedCoreDataStack] saveContext];
                
                hud.labelText = NSLocalizedString(@"Data Updated", nil);
                [hud show:YES];
                [hud hide:YES afterDelay:HUD_TIME_DELAY];
            }else{
                hud.labelText = [responseData valueForKey:@"ret_msg"];
                [hud show:YES];
                [hud hide:YES afterDelay:HUD_TIME_DELAY];
            }
        }
        
        [self.refreshView finishLoading];
        
    }];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"AddMedicalRecord"])
    {
        MedicalRecordEditViewController *addVC = [segue destinationViewController];
        addVC.title = NSLocalizedString(@"Add Medical Record", nil);
        addVC.medicalHistoryType = MedicalHistoryTypeAdd;
    }
    
    if ([segue.identifier isEqualToString:@"EditMedicalRecord"])
    {
        MedicalRecordEditViewController *editVC = [segue destinationViewController];
        
        editVC.title = NSLocalizedString(@"Edit Meical Record", nil);
        SectionHeaderView *sectionHeaderView = (SectionHeaderView *)sender;
        editVC.medicalHistoryType = MedicalHistoryTypeEdit;
        editVC.medicalRecord = self.fetchController.fetchedObjects[sectionHeaderView.section];
    }
    
    if ([segue.identifier isEqualToString:@"MedicalRecordInfo"])
    {
        
        PatientDataViewController *patientDataVC = [segue destinationViewController];
        NSIndexPath *selectedIndexPath = [self.tableView indexPathForSelectedRow];
        patientDataVC.medicalRecord = self.fetchController.fetchedObjects[selectedIndexPath.section];
    }
}

#pragma mark - NSFetchedResultController

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self configureNoDataView];
    [self.tableView reloadData];
}

- (void)configureNoDataView
{
    if (self.fetchController.fetchedObjects.count > 0) {
        self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    }else{
        self.tableView.tableFooterView = [[NSBundle mainBundle] loadNibNamed:@"NoDataTips" owner:self options:nil][0];
    }
}

#pragma mark - Table view data source / delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.

    return [self.fetchController.fetchedObjects count];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    SectionHeaderView *headerView = [self.tableView dequeueReusableHeaderFooterViewWithIdentifier:SectionHeaderViewIdentifier];
    [self configureHeaderView:headerView inSection:section];
    
    return  headerView;
}

- (void)configureHeaderView:(SectionHeaderView *)headerView inSection:(NSInteger)section
{
    MedicalRecord *mediclaRecord = self.fetchController.fetchedObjects[section];
    headerView.titleLabel.text = mediclaRecord.mediName ;
    headerView.arrowBtn.selected = NO;
    headerView.section = section;
    headerView.delegate = self;
    
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:section];
    if ([self.selectedArray containsObject:indexPath]) {
        [headerView toggleOpenWithUserAction:YES];
    }
    
    //    if (!self.openSectionHeaderView) {
    //        if (section == 0) {
    //            [headerView toggleOpenWithUserAction:YES];
    //        }
    //    }
    //    else {
    //        if ([self.selectedArray count] > 0) {
    //            NSIndexPath *openSectionIndexPath = self.selectedArray[0];
    //            NSInteger openSectionIndex = openSectionIndexPath.section;
    //            if (openSectionIndex == section) {
    //                headerView.arrowBtn.selected = YES;
    //                // !important you have to re-point to the openSectionHeaderView while tableView refresh itself
    //                self.openSectionHeaderView = headerView;
    //            }
    //        }
    //    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:section];
    if ([self.selectedArray containsObject:indexPath]) {
        return 1;
    } else return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MedicalHistoryDetailCell *cell = [tableView dequeueReusableCellWithIdentifier:MedicalHistoryCellIndentifier forIndexPath:indexPath];
    [self configureMedicalHistoryDetailCell:cell indexPath:indexPath];
    return cell;
}

- (void)configureMedicalHistoryDetailCell:(MedicalHistoryDetailCell *)cell indexPath:(NSIndexPath *)indexPath
{
    MedicalRecord *medicalRecord = self.fetchController.fetchedObjects[indexPath.section];
    cell.diseaseNameLabel.text = medicalRecord.mediName;
    cell.comfirmedDateLabel.text = medicalRecord.diagTime;
    cell.comfirmedHospitalLabel.text = medicalRecord.diagHosp;
    cell.patientDataLabel.text = medicalRecord.mediRecord;
    cell.treatmentConditionLabel.text = medicalRecord.treatMent;
    cell.treatmentScheduleLabel.text = medicalRecord.treatPlan;
    [self setupConstraintsForCell:cell];
}

- (void)deleteMedicalRecord:(MedicalRecord *)medicalRecord
{
    hud = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
    [self.navigationController.view addSubview:hud];
    hud.mode = MBProgressHUDModeText;
    
    NSDictionary *parameters = @{@"method":@"mediRecordDelete",
                                 @"sign":@"sign",
                                 @"sessionId":[NSString sessionID],
                                 @"mediHistId":medicalRecord.mediHistId};
    [GCRequest userDeleteMedicalRecordWithParameters:parameters withBlock:^(NSDictionary *responseData, NSError *error) {
        if (!error) {
            NSString *ret_code = [responseData objectForKey:@"ret_code"];

            if ([ret_code isEqualToString:@"0"]) {
                
                [medicalRecord deleteEntityInContext:[CoreDataStack sharedCoreDataStack].context];
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
    }];

}

- (void)setupConstraintsForCell:(UITableViewCell *)cell
{
    [cell setNeedsUpdateConstraints];
    [cell updateConstraintsIfNeeded];
}

#pragma mark - TableViewDelegate

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        MedicalRecord *medicalRecord = self.fetchController.fetchedObjects[indexPath.section];
        [self deleteMedicalRecord:medicalRecord];
    }
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self heightForBasicCellAtIndexPath:indexPath];
}

- (CGFloat)heightForBasicCellAtIndexPath:(NSIndexPath *)indexPath
{
    static MedicalHistoryDetailCell *sizingCell = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sizingCell = [self.tableView dequeueReusableCellWithIdentifier:@"MedicalHistoryDetailCell"];
    });
    [self configureMedicalHistoryDetailCell:sizingCell indexPath:indexPath];
    return [self calculateHeightForConfiguredSizingCell:sizingCell];
}

- (CGFloat)calculateHeightForConfiguredSizingCell:(MedicalHistoryDetailCell *)sizingCell
{
    sizingCell.bounds = CGRectMake(0.0f, 0.0f, CGRectGetWidth(self.tableView.bounds), CGRectGetHeight(sizingCell.bounds));
    [sizingCell setNeedsLayout];
    [sizingCell layoutIfNeeded];
    
    CGSize size = [sizingCell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
    return size.height;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - SectionHeaderViewDelegate

- (void)sectionHeaderView:(SectionHeaderView *)sectionHeaderView sectionOpened:(NSInteger)section
{
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:section];
    
    if (![self.selectedArray containsObject:indexPath]) {
        [self.selectedArray addObject:indexPath];
        
        [self.tableView beginUpdates];
        [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationLeft];
        [self.tableView endUpdates];
    }
}

- (void)sectionHeaderView:(SectionHeaderView *)sectionHeaderView sectionClosed:(NSInteger)section
{
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:section];
    [self.selectedArray removeObject:indexPath];
    [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationRight];
    //    self.openSectionHeaderView = nil;
}

- (void)sectionHeaderView:(SectionHeaderView *)sectionHeaderView sectionEdited:(NSInteger)section
{
    [self performSegueWithIdentifier:@"EditMedicalRecord" sender:sectionHeaderView];
}


- (void)addMedicalData:(id)sender
{
    [self performSegueWithIdentifier:@"AddMedicalRecord" sender:nil];
}

- (IBAction)back:(UIStoryboardSegue *)segue
{
    [self.tableView reloadData];
    
}



@end
