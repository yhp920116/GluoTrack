//
//  LeftMenuController.m
//  SugarNursing
//
//  Created by Dan on 14-11-5.
//  Copyright (c) 2014年 Tisson. All rights reserved.
//

#import "LeftMenuController.h"
#import "LeftMenuCell.h"
#import "MemberInfoCell.h"
#import "PersonalInfoViewController.h"
#import "UIStoryboard+Storyboards.h"
#import "MemberCenterViewController.h"
#import "AppDelegate+UserLogInOut.h"
#import "TestTrackerViewController.h"
#import "RecoveryLogViewController.h"
#import "ControlEffectViewController.h"
#import "RemindViewController.h"
#import "UtilsMacro.h"

@interface LeftMenuController ()<UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate>

@property (weak, nonatomic) IBOutlet UITableView *leftMenu;

@property (nonatomic, strong) NSFetchedResultsController *fetchController;
@property (nonatomic, strong) NSArray *menuArray;
@property (nonatomic) NSInteger selectedIndex;



@end

@implementation LeftMenuController

- (void)awakeFromNib
{
    [super awakeFromNib];
    _selectedIndex = -1;
    if (!self.menuArray) {
        self.menuArray  = @[
                            @[NSLocalizedString(@"Test Result",),@"Test"],
                            @[NSLocalizedString(@"Control Effect",),@"Effect"],
                            @[NSLocalizedString(@"Recovery Log",),@"Recovery"],
//                            @[NSLocalizedString(@"My Tips",),@"Remind"],
                            @[NSLocalizedString(@"Service Center",),@"Service"],
                            @[NSLocalizedString(@"Advise",),@"Advise"],
                            @[NSLocalizedString(@"Member Center",),@"Center"],
                            @[NSLocalizedString(@"Log Out",),@"IconEmpty"],
                            ];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self configureFetchController];
    [self configureUserInfo];
    [self configureMenu];
}

- (void)configureFetchController
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"userid.linkManId = %@ && userid.userId = %@",[NSString linkmanID], [NSString userID]];
    self.fetchController = [UserInfo fetchAllGroupedBy:nil sortedBy:@"userid.userId" ascending:YES withPredicate:predicate delegate:self incontext:[CoreDataStack sharedCoreDataStack].context];
}

- (void)configureMenu
{    
    self.leftMenu.rowHeight = UITableViewAutomaticDimension;
    self.leftMenu.estimatedRowHeight = 100;
}

- (void)configureUserInfo
{
    //Get UserInfo after Logining
    
    NSDictionary *parameters = @{@"method":@"getPersonalInfo",
                                 @"sessionId":[NSString sessionID],
                                 @"linkManId":[NSString linkmanID],
                                 @"sign":@"sign"};
    
    [GCRequest userGetInfoWithParameters:parameters withBlock:^(NSDictionary *responseData, NSError *error) {
        
        // 这里无论获取用户信息的请求是成功还是失败，在CoreData中至少都要创建一个以userID为主键的userInfo（用户能登陆入主界面，已经存在userid和linkmandid)
        
        UserInfo *userInfo;
        UserID *userID;
        
        if ( 0 == self.fetchController.fetchedObjects.count) {
            userInfo = [UserInfo createEntityInContext:[CoreDataStack sharedCoreDataStack].context];
            userID= [UserID createEntityInContext:[CoreDataStack sharedCoreDataStack].context];
            userID.userId = [NSString userID];
            userID.linkManId = [NSString linkmanID];
            userInfo.userid = userID;
            
        }else{
            userInfo = self.fetchController.fetchedObjects[0];
            userID = userInfo.userid;
        }
        
        if (!error) {
            
            NSString *ret_code = [responseData objectForKey:@"ret_code"];
            
            if ([ret_code isEqualToString:@"0"]) {
                
                // Save userInformation to CoreData
                
                responseData = [[responseData objectForKey:@"linkManInfo"] mutableCopy];
                
                // Formatting responseData to coreData
                [responseData dateFormattingToUser:@"yyyy-MM-dd" ForKey:@"birthday"];
                [responseData sexFormattingToUserForKey:@"sex"];
                [responseData serverLevelFormattingToUserForKey:@"servLevel"];
                
                [userInfo updateCoreDataForData:responseData withKeyPath:nil];
                
            }else{
                [NSString localizedMsgFromRet_code:ret_code withHUD:NO];
            }
                
        }
        
        [[CoreDataStack sharedCoreDataStack] saveContext];
        
        DDLogDebug(@"Saving UserInfo :%@",userInfo);
        
    }];
    
}

#pragma mark - NSFetchResultControllerDelegate

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    [self.leftMenu reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}

#pragma mark - TableViewDelegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.menuArray.count+1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 0) {
        return 140;
    } else return 52;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 0 ) {
        MemberInfoCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MemberInfoCell" forIndexPath:indexPath];
        [self configureMemberInfoCell:cell atIndexPath:indexPath];
        return cell;
    }
    LeftMenuCell *cell = [tableView dequeueReusableCellWithIdentifier:@"LeftMenuCell" forIndexPath:indexPath];
    cell.backgroundColor = [UIColor clearColor];
    cell.contentView.backgroundColor = [UIColor clearColor];
    [cell configureCellWithIconName:self.menuArray[indexPath.row-1][1] LabelText:self.menuArray[indexPath.row-1][0]];
    return cell;
}

- (void)configureMemberInfoCell:(MemberInfoCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    cell.backgroundColor = [UIColor clearColor];
    cell.contentView.backgroundColor = [UIColor clearColor];
    
    UserInfo *userInfo;
    if ([self.fetchController.fetchedObjects count] == 0) {
        userInfo = nil;
    }else{
        userInfo = self.fetchController.fetchedObjects[0];
    }
    [cell.thumbnailView sd_setImageWithURL:[NSURL URLWithString:userInfo.headImageUrl] placeholderImage:[UIImage imageNamed:@"thumbDefault"]];
    cell.userNameLabel.text = userInfo.userName;
    
    int age;

    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"YYYY-MM-dd"];
    NSDate *birthDate = [dateFormatter dateFromString:userInfo.birthday];
    NSTimeInterval dateDiff = [birthDate timeIntervalSinceNow];
    age = abs(trunc(dateDiff/(60*60*24))/365);
    
    cell.sexAndAgeLabel.text = [NSString stringWithFormat:@"%@   %d%@",userInfo.sex,age,NSLocalizedString(@"years old", nil)];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (self.selectedIndex == indexPath.row) {
        [self.sideMenuViewController hideMenuViewController];
        return;
    } else {
        self.selectedIndex = indexPath.row;
        [self switchToViewControllerAtIndex:self.selectedIndex];
    }

}

- (void)switchToViewControllerAtIndex:(NSInteger)index
{
    switch (index) {
        case 0:
        {
            [self.sideMenuViewController setContentViewController:[[UIStoryboard memberCenterStoryboard] instantiateInitialViewController] animated:YES];
            [self.sideMenuViewController hideMenuViewController];
//            PersonalInfoViewController *personalInfo = [[UIStoryboard memberCenterStoryboard] instantiateViewControllerWithIdentifier:@"PersonalInfo"];
//            [personalInfo.navigationItem setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:@"菜单" style:UIBarButtonItemStyleDone target:self action:@selector(menu:)]];
//            UINavigationController *personalInfoNav = [[UINavigationController alloc] initWithRootViewController:personalInfo];
//            [self.sideMenuViewController setContentViewController:personalInfoNav animated:YES];
//            [self.sideMenuViewController hideMenuViewController];
            break;
        }
        case 1:
            [self.sideMenuViewController setContentViewController:[[UIStoryboard testTracker] instantiateInitialViewController] animated:YES];
            [self.sideMenuViewController hideMenuViewController];
            break;
        case 2:
            [self.sideMenuViewController setContentViewController:[[UIStoryboard controlEffect] instantiateInitialViewController] animated:YES];
            [self.sideMenuViewController hideMenuViewController];
            break;
        case 3:
            [self.sideMenuViewController setContentViewController:[[UIStoryboard recoveryLog] instantiateInitialViewController]];
            [self.sideMenuViewController hideMenuViewController];
            break;
//        case 4:
//            [self.sideMenuViewController setContentViewController:[[UIStoryboard myRemind] instantiateInitialViewController]];
//            [self.sideMenuViewController hideMenuViewController];
//            break;
        case 4:
            [self.sideMenuViewController setContentViewController:[[UIStoryboard myService] instantiateInitialViewController]];
            [self.sideMenuViewController hideMenuViewController];
            break;
        case 5:
            [self.sideMenuViewController setContentViewController:[[UIStoryboard advise] instantiateInitialViewController]];
            [self.sideMenuViewController hideMenuViewController];
            break;
        case 6:
            [self.sideMenuViewController setContentViewController:[[UIStoryboard memberCenterStoryboard] instantiateInitialViewController] animated:YES];
            [self.sideMenuViewController hideMenuViewController];
            break;
        case 7:
            [AppDelegate userLogOut];
            break;
        default:
            break;
    }
}

- (void)menu:(id)sender
{
    [self.sideMenuViewController presentLeftMenuViewController];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
