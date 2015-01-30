//
//  AdviseViewController.m
//  SugarNursing
//
//  Created by Dan on 14-11-26.
//  Copyright (c) 2014年 Tisson. All rights reserved.
//

#import "AdviseViewController.h"
#import "AdviseCell.h"
#import <SSPullToRefresh.h>
#import "UtilsMacro.h"
#import "NoDataView.h"

@interface AdviseViewController ()<UITableViewDataSource,UITableViewDelegate,SSPullToRefreshViewDelegate,NSFetchedResultsControllerDelegate>{
}

@property (strong, nonatomic) NSFetchedResultsController *fetchController;
@property (strong, nonatomic) SSPullToRefreshView *pullToRefreshView;

@end

@implementation AdviseViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.tableView.estimatedRowHeight = UITableViewAutomaticDimension;
    [self configureFetchController];
    [self configureNoDataView];
}

- (void)viewDidLayoutSubviews
{
    if (self.pullToRefreshView == nil) {
        self.pullToRefreshView = [[SSPullToRefreshView alloc] initWithScrollView:self.tableView delegate:self];
        [self.pullToRefreshView startLoadingAndExpand:YES animated:YES];
    }

}

- (void)configureFetchController
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"userid.userId = %@ && userid.linkManId = %@",[NSString userID],[NSString linkmanID]];
    self.fetchController = [Advise fetchAllGroupedBy:nil sortedBy:@"adviceTime" ascending:YES withPredicate:predicate delegate:self incontext:[CoreDataStack sharedCoreDataStack].context];
}

#pragma mark - SSPullToRefreshViewDelegate

- (void)pullToRefreshViewDidStartLoading:(SSPullToRefreshView *)view
{
    [self getDoctorSuggestions];
}

#pragma mark - NSFetchController Delegate

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self configureNoDataView];
    [self.tableView reloadData];
}

- (void)getDoctorSuggestions
{
    NSDictionary *parameters = @{@"method":@"getDoctorSuggests",
                                 @"sign":@"sign",
                                 @"sessionId":[NSString sessionID],
                                 @"linkManId":[NSString linkmanID],};
    
    [GCRequest userGetDoctorSuggestionWithParameters:parameters withBlock:^(NSDictionary *responseData, NSError *error) {
        
        if (!error) {
            NSString *ret_code = [responseData valueForKey:@"ret_code"];
            if ([ret_code isEqualToString:@"0"]) {
                
                // 清除缓存
                for (Advise *advise in self.fetchController.fetchedObjects) {
                    [advise deleteEntityInContext:[CoreDataStack sharedCoreDataStack].context];
                }
                
                NSArray *adviseArray;
                
                if ([[responseData objectForKey:@"suggestList"] isKindOfClass:[NSArray class]]) {
                    adviseArray = [responseData objectForKey:@"suggestList"];
                }else{
                    adviseArray = @[];
                }
               
                for (NSDictionary *adviseDic in adviseArray) {
                    
                    NSMutableDictionary *adviseDic_ = [adviseDic mutableCopy];
                    [adviseDic_ dateFormattingToUser:@"yyyy-MM-dd HH:mm:ss" ForKey:@"adviceTime"];
                    
                    Advise *advise =[Advise createEntityInContext:[CoreDataStack sharedCoreDataStack].context];
                    [advise updateCoreDataForData:adviseDic_ withKeyPath:nil];
                    
                    UserID *userID = [UserID createEntityInContext:[CoreDataStack sharedCoreDataStack].context];
                    userID.userId = [NSString userID];
                    userID.linkManId = [NSString linkmanID];
                    advise.userid = userID;
                }
                
                [[CoreDataStack sharedCoreDataStack] saveContext];
                
            }
        }
        [self.pullToRefreshView finishLoading];
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

#pragma mark - TableView DataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.fetchController.fetchedObjects.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIndentifier = @"AdviseCell";
    AdviseCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIndentifier forIndexPath:indexPath];
    
    [self configureAdviseCell:cell indexPath:indexPath];
    return cell;
}

- (void)setupConstraintsWithCell:(UITableViewCell *)cell
{
    [cell setNeedsUpdateConstraints];
    [cell updateConstraintsIfNeeded];
}

- (void)configureAdviseCell:(AdviseCell *)cell indexPath:(NSIndexPath *)indexPath
{
    Advise *advise = [self.fetchController.fetchedObjects objectAtIndex:indexPath.row];
    
    cell.adviseLabel.text = advise.content;
    cell.dateLabel.text = advise.adviceTime;
    
    [self setupConstraintsWithCell:cell];
}

#pragma mark - TableViewDelegate


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self heightForBasicCellAtIndexPath:indexPath];
}

- (CGFloat)heightForBasicCellAtIndexPath:(NSIndexPath *)indexPath
{
    static AdviseCell *sizingCell = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sizingCell = [self.tableView dequeueReusableCellWithIdentifier:@"AdviseCell"];
    });
    [self configureAdviseCell:sizingCell indexPath:indexPath];
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (!tableView.editing) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}



@end
