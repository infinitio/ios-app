//
//  InfinitSettingsViewController.m
//  Infinit
//
//  Created by Christopher Crone on 19/01/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitSettingsViewController.h"

#import "InfinitColor.h"
#import "InfinitSettingsUserCell.h"
#import "InfinitTabBarController.h"

#import <Gap/InfinitStateManager.h>
#import <Gap/InfinitStateResult.h>
#import <Gap/InfinitUserManager.h>

typedef NS_ENUM(NSUInteger, InfinitSettingsSections)
{
  InfinitSettingsSectionAccount = 0,
  InfinitSettingsSectionFeedback,
  InfinitSettingsSectionLogout,
};

typedef NS_ENUM(NSUInteger, InfinitLogoutSettings)
{
  InfinitLogoutSettingLogout = 0,
};

@interface InfinitSettingsViewController ()

@property (nonatomic, weak) IBOutlet InfinitSettingsUserCell* user_cell;

@end

@implementation InfinitSettingsViewController

- (void)viewDidLoad
{
  self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
  [super viewDidLoad];
  NSDictionary* nav_bar_attrs = @{NSFontAttributeName: [UIFont fontWithName:@"SourceSansPro-Bold"
                                                                       size:17.0f],
                                  NSForegroundColorAttributeName: [InfinitColor colorWithRed:81
                                                                                       green:81
                                                                                        blue:73]};
  [self.navigationController.navigationBar setTitleTextAttributes:nav_bar_attrs];
}

- (void)viewWillAppear:(BOOL)animated
{
  [self.user_cell configureWithUser:[[InfinitUserManager sharedInstance] me]];
  [super viewWillAppear:animated];
}

#pragma mark - Table View Delegate

- (void)tableView:(UITableView*)tableView
didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
  if (indexPath.section == InfinitSettingsSectionLogout &&
      indexPath.row == InfinitLogoutSettingLogout)
  {
    [[InfinitStateManager sharedInstance] logoutPerformSelector:@selector(logoutCallback:)
                                                       onObject:self];
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
  }
}

- (CGFloat)tableView:(UITableView*)tableView
heightForHeaderInSection:(NSInteger)section
{
  return 1.0f;
}

- (CGFloat)tableView:(UITableView*)tableView
heightForFooterInSection:(NSInteger)section
{
  return 32.0f;
}

- (UIView*)tableView:(UITableView*)tableView
viewForHeaderInSection:(NSInteger)section
{
  return [[UIView alloc] initWithFrame:CGRectZero];
}

- (UIView*)tableView:(UITableView*)tableView
viewForFooterInSection:(NSInteger)section
{
  return [[UIView alloc] initWithFrame:CGRectZero];
}

#pragma mark - Callbacks

- (void)logoutCallback:(InfinitStateResult*)result
{
  if (result.success)
  {
    [(InfinitTabBarController*)self.tabBarController showWelcomeScreen];
  }
}

@end
