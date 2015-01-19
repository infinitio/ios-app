//
//  InfinitSettingsViewController.m
//  Infinit
//
//  Created by Christopher Crone on 19/01/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitSettingsViewController.h"

#import "InfinitTabBarController.h"

#import <Gap/InfinitStateManager.h>
#import <Gap/InfinitStateResult.h>

typedef NS_ENUM(NSUInteger, InfinitSettingsSections)
{
  InfinitSettingsSectionAccount = 0,
};

typedef NS_ENUM(NSUInteger, InfinitAccountSettings)
{
  InfinitAccountSettingsLogout = 0,
};

@interface InfinitSettingsViewController ()

@end

@implementation InfinitSettingsViewController

- (void)viewDidLoad
{
  self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
  [super viewDidLoad];
}

#pragma mark - Table View Delegate

- (void)tableView:(UITableView*)tableView
didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
  if (indexPath.section == InfinitSettingsSectionAccount)
  {
    if (indexPath.row == InfinitAccountSettingsLogout)
    {
      [[InfinitStateManager sharedInstance] logoutPerformSelector:@selector(logoutCallback:)
                                                         onObject:self];
      [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
  }
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
