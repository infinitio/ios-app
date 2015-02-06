//
//  InfinitSettingsViewController.m
//  Infinit
//
//  Created by Christopher Crone on 19/01/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitSettingsViewController.h"

#import "InfinitColor.h"
#import "InfinitSettingsCell.h"
#import "InfinitSettingsReportProblemController.h"
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

  InfinitSettingsSectionCount,
};

typedef NS_ENUM(NSUInteger, InfinitAccountSettings)
{
  InfinitAccountSettingUser = 0,
  InfinitAccountSettingEdit,

  InfinitAccountSettingsCount
};

typedef NS_ENUM(NSUInteger, InfinitFeedbackSettings)
{
  InfinitFeedbackSettingRate = 0,
  InfinitFeedbackSettingFeedback,
  InfinitFeedbackSettingProblem,

  InfinitFeedbackSettingsCount,
};

typedef NS_ENUM(NSUInteger, InfinitLogoutSettings)
{
  InfinitLogoutSettingLogout = 0,

  InfinitLogoutSettingsCount,
};

@interface InfinitSettingsViewController ()

@end

@implementation InfinitSettingsViewController
{
@private
  BOOL _logging_out;
  NSString* _norm_cell_id;
  NSString* _user_cell_id;
}

- (void)viewDidLoad
{
  _norm_cell_id = @"settings_cell";
  _user_cell_id = @"settings_user_cell";
  self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
  _logging_out = NO;
  [super viewDidLoad];
  NSDictionary* nav_bar_attrs = @{NSFontAttributeName: [UIFont fontWithName:@"SourceSansPro-Bold"
                                                                       size:17.0f],
                                  NSForegroundColorAttributeName: [InfinitColor colorWithRed:81
                                                                                       green:81
                                                                                        blue:73]};
  [self.navigationController.navigationBar setTitleTextAttributes:nav_bar_attrs];
  UINib* norm_cell_nib = [UINib nibWithNibName:NSStringFromClass(InfinitSettingsCell.class)
                                        bundle:nil];
  [self.tableView registerNib:norm_cell_nib forCellReuseIdentifier:_norm_cell_id];
  UINib* user_cell_nib = [UINib nibWithNibName:NSStringFromClass(InfinitSettingsUserCell.class)
                                        bundle:nil];
  [self.tableView registerNib:user_cell_nib forCellReuseIdentifier:_user_cell_id];
}

- (void)viewWillAppear:(BOOL)animated
{
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(avatarUpdated:)
                                               name:INFINIT_USER_AVATAR_NOTIFICATION
                                             object:nil];
  [super viewWillAppear:animated];
  InfinitSettingsUserCell* cell =
    (InfinitSettingsUserCell*)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0
                                                                                       inSection:0]];
  [cell configureWithUser:[InfinitUserManager sharedInstance].me];
}

- (void)viewWillDisappear:(BOOL)animated
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [super viewWillDisappear:animated];
}

#pragma mark - User Avatar

- (void)avatarUpdated:(NSNotification*)notification
{
  InfinitUser* self_user = [[InfinitUserManager sharedInstance] me];
  if ([notification.userInfo[@"id"] isEqualToNumber:self_user.id_])
  {
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]]
                          withRowAnimation:UITableViewRowAnimationAutomatic];
  }
}

#pragma mark - Table View Datasource

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
  return InfinitSettingsSectionCount;
}


- (NSInteger)tableView:(UITableView*)tableView
 numberOfRowsInSection:(NSInteger)section
{
  switch (section)
  {
    case InfinitSettingsSectionAccount:
      return InfinitAccountSettingsCount;
    case InfinitSettingsSectionFeedback:
      return InfinitFeedbackSettingsCount;
    case InfinitSettingsSectionLogout:
      return InfinitLogoutSettingsCount;

    default:
      return 0;
  }
}

- (UITableViewCell*)tableView:(UITableView*)tableView
        cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
  UITableViewCell* res = nil;
  if (indexPath.section == InfinitSettingsSectionAccount)
  {
    switch (indexPath.row)
    {
      case InfinitAccountSettingUser:
      {
       InfinitSettingsUserCell* cell =
          [self.tableView dequeueReusableCellWithIdentifier:_user_cell_id forIndexPath:indexPath];
        [cell configureWithUser:[InfinitUserManager sharedInstance].me];
        res = cell;
        break;
      }
      case InfinitAccountSettingEdit:
      {
        InfinitSettingsCell* cell = [self.tableView dequeueReusableCellWithIdentifier:_norm_cell_id
                                                                         forIndexPath:indexPath];
        cell.icon_view.image = [UIImage imageNamed:@"icon-settings-fullname"];
        cell.title_label.text = NSLocalizedString(@"Edit profile", nil);
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        res = cell;
        break;
      }
    }
  }
  else if (indexPath.section == InfinitSettingsSectionFeedback)
  {
    InfinitSettingsCell* cell = [self.tableView dequeueReusableCellWithIdentifier:_norm_cell_id
                                                                     forIndexPath:indexPath];
    switch (indexPath.row)
    {
      case InfinitFeedbackSettingRate:
      {
        cell.icon_view.image = [UIImage imageNamed:@"icon-settings-rate"];
        cell.title_label.text = NSLocalizedString(@"Rate us", nil);
        break;
      }
      case InfinitFeedbackSettingFeedback:
      {
        cell.icon_view.image = [UIImage imageNamed:@"icon-feedback"];
        cell.title_label.text = NSLocalizedString(@"Send feedback", nil);
        break;
      }
      case InfinitFeedbackSettingProblem:
      {
        cell.icon_view.image = [UIImage imageNamed:@"icon-settings-flag"];
        cell.title_label.text = NSLocalizedString(@"Report a problem", nil);
        break;
      }
    }
    res = cell;
  }
  else if (indexPath.section == InfinitSettingsSectionLogout)
  {
    InfinitSettingsCell* cell = [self.tableView dequeueReusableCellWithIdentifier:_norm_cell_id
                                                                     forIndexPath:indexPath];
    cell.title_label.textColor = [InfinitColor colorFromPalette:ColorBurntSienna];
    cell.title_label.text = NSLocalizedString(@"Logout", nil);
    cell.icon_view.image = [UIImage imageNamed:@"icon-settings-logout"];
    res = cell;
  }
  return res;
}

#pragma mark - Table View Delegate

- (CGFloat)tableView:(UITableView*)tableView
heightForRowAtIndexPath:(NSIndexPath*)indexPath
{
  if (indexPath.section == InfinitSettingsSectionAccount)
  {
    switch (indexPath.row)
    {
      case InfinitAccountSettingUser:
        return 182.0f;

      default:
        return 50.0f;
    }
  }
  else if (indexPath.section == InfinitSettingsSectionFeedback)
  {
    return 50.0f;
  }
  else if (indexPath.section == InfinitSettingsSectionLogout)
  {
    return 50.0f;
  }
  return 0.0f;
}

- (void)tableView:(UITableView*)tableView
didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
  if (_logging_out)
    return;

  if (indexPath.section == InfinitSettingsSectionAccount)
  {
    switch (indexPath.row)
    {
      case InfinitAccountSettingEdit:
        [self performSegueWithIdentifier:@"settings_edit_profile" sender:self];
        break;

      default:
        break;
    }
  }
  else if (indexPath.section == InfinitSettingsSectionFeedback)
  {
    switch (indexPath.row)
    {
      case InfinitFeedbackSettingRate:
      {
        NSString* itunes_link = @"https://itunes.apple.com/us/app/apple-store/id955849852";
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:itunes_link]];
        break;
      }
      case InfinitFeedbackSettingFeedback:
        [self performSegueWithIdentifier:@"settings_feedback" sender:self];
        break;
      case InfinitFeedbackSettingProblem:
        [self performSegueWithIdentifier:@"settings_report_problem" sender:self];
        break;

      default:
        break;
    }
  }
  else if (indexPath.section == InfinitSettingsSectionLogout &&
           indexPath.row == InfinitLogoutSettingLogout)
  {
    _logging_out = YES;
    [[InfinitStateManager sharedInstance] logoutPerformSelector:@selector(logoutCallback:)
                                                       onObject:self];
  }
  [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
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
  _logging_out = NO;
  if (result.success)
  {
    [(InfinitTabBarController*)self.tabBarController showWelcomeScreen];
  }
}

#pragma mark - Segue

- (void)prepareForSegue:(UIStoryboardSegue*)segue
                 sender:(id)sender
{
  if ([segue.identifier isEqualToString:@"settings_report_problem"])
  {
    InfinitSettingsReportProblemController* controller =
      ((UINavigationController*)segue.destinationViewController).viewControllers[0];
    controller.feedback_mode = NO;
  }
  else if ([segue.identifier isEqualToString:@"settings_feedback"])
  {
    InfinitSettingsReportProblemController* controller =
      ((UINavigationController*)segue.destinationViewController).viewControllers[0];
    controller.feedback_mode = YES;
  }
}

@end
