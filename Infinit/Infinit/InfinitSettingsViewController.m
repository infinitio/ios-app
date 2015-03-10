//
//  InfinitSettingsViewController.m
//  Infinit
//
//  Created by Christopher Crone on 19/01/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitSettingsViewController.h"

#import "InfinitColor.h"
#import "InfinitHostDevice.h"
#import "InfinitLoginInvitationCodeController.h"
#import "InfinitSettingsCell.h"
#import "InfinitSettingsExpandedCell.h"
#import "InfinitSettingsReportProblemController.h"
#import "InfinitSettingsUserCell.h"
#import "InfinitTabBarController.h"

#import <Gap/InfinitConnectionManager.h>
#import <Gap/InfinitStateManager.h>
#import <Gap/InfinitStateResult.h>
#import <Gap/InfinitUserManager.h>

typedef NS_ENUM(NSUInteger, InfinitSettingsSections)
{
  InfinitSettingsSectionAccount = 0,
  InfinitSettingsSectionOther,
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

typedef NS_ENUM(NSUInteger, InfinitOtherSettings)
{
  InfinitOtherSettingEnterCode = 0,

  InfinitOtherSettingsCount
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

@interface InfinitSettingsViewController () <UIAlertViewDelegate,
                                             UITableViewDataSource,
                                             UITableViewDelegate>

@property (nonatomic, weak) IBOutlet UITableView* table_view;

@end

@implementation InfinitSettingsViewController
{
@private
  BOOL _logging_out;
  NSString* _norm_cell_id;
  NSString* _expanded_cell_id;
  NSString* _user_cell_id;
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
  _norm_cell_id = @"settings_cell";
  _expanded_cell_id = @"settings_expanded_cell";
  _user_cell_id = @"settings_user_cell";
  self.table_view.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
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
  [self.table_view registerNib:norm_cell_nib forCellReuseIdentifier:_norm_cell_id];
  UINib* expanded_cell_nib =
    [UINib nibWithNibName:NSStringFromClass(InfinitSettingsExpandedCell.class) bundle:nil];
  [self.table_view registerNib:expanded_cell_nib forCellReuseIdentifier:_expanded_cell_id];
  UINib* user_cell_nib = [UINib nibWithNibName:NSStringFromClass(InfinitSettingsUserCell.class)
                                        bundle:nil];
  [self.table_view registerNib:user_cell_nib forCellReuseIdentifier:_user_cell_id];
}

- (void)viewWillAppear:(BOOL)animated
{
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(avatarUpdated:)
                                               name:INFINIT_USER_AVATAR_NOTIFICATION
                                             object:nil];
  [super viewWillAppear:animated];
  InfinitSettingsUserCell* cell =
    (InfinitSettingsUserCell*)[self.table_view cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0
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
    [self.table_view reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]]
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
    case InfinitSettingsSectionOther:
      return InfinitOtherSettingsCount;
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
          [self.table_view dequeueReusableCellWithIdentifier:_user_cell_id forIndexPath:indexPath];
        [cell configureWithUser:[InfinitUserManager sharedInstance].me];
        res = cell;
        break;
      }
      case InfinitAccountSettingEdit:
      {
        InfinitSettingsCell* cell = [self.table_view dequeueReusableCellWithIdentifier:_norm_cell_id
                                                                         forIndexPath:indexPath];
        cell.icon_view.image = [UIImage imageNamed:@"icon-settings-fullname"];
        cell.title_label.text = NSLocalizedString(@"Edit profile", nil);
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        res = cell;
        break;
      }
    }
  }
  else if (indexPath.section == InfinitSettingsSectionOther)
  {
    InfinitSettingsExpandedCell* cell =
      [self.table_view dequeueReusableCellWithIdentifier:_expanded_cell_id forIndexPath:indexPath];
    switch (indexPath.row)
    {
      case InfinitOtherSettingEnterCode:
        cell.icon_view.image = [UIImage imageNamed:@"icon-code"];
        cell.title_label.text = NSLocalizedString(@"Enter a code", nil);
        cell.info_label.text = NSLocalizedString(@"Retrieve files from an invitation", nil);
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        break;
    }
    res = cell;
  }
  else if (indexPath.section == InfinitSettingsSectionFeedback)
  {
    InfinitSettingsCell* cell = [self.table_view dequeueReusableCellWithIdentifier:_norm_cell_id
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
    InfinitSettingsCell* cell = [self.table_view dequeueReusableCellWithIdentifier:_norm_cell_id
                                                                     forIndexPath:indexPath];
    cell.title_label.textColor = [InfinitColor colorFromPalette:InfinitPaletteColorBurntSienna];
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
  else if (indexPath.section == InfinitSettingsSectionOther)
  {
    return 68.0f;
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
      {
        if ([InfinitConnectionManager sharedInstance].connected == NO)
        {
          NSString* title = NSLocalizedString(@"Need a connection!", nil);
          NSString* message =
            NSLocalizedString(@"Unable to edit your profile without an Internet connection.", nil);
          UIAlertView* alert = [[UIAlertView alloc] initWithTitle:title
                                                          message:message
                                                         delegate:self
                                                cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                                otherButtonTitles:nil];
          [alert show];
        }
        else
        {
          [self performSegueWithIdentifier:@"settings_edit_profile" sender:self];
        }
      }
        break;

      default:
        break;
    }
  }
  else if (indexPath.section == InfinitSettingsSectionOther)
  {
    switch (indexPath.row)
    {
      case InfinitOtherSettingEnterCode:
        [self performSegueWithIdentifier:@"settings_invite_code_segue" sender:self];
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
  [self.table_view deselectRowAtIndexPath:indexPath animated:YES];
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
    InfinitSettingsReportProblemController* controller = nil;
    if ([InfinitHostDevice iOS7])
      controller = segue.destinationViewController;
    else
      controller = ((UINavigationController*)segue.destinationViewController).viewControllers[0];
    controller.feedback_mode = NO;
  }
  else if ([segue.identifier isEqualToString:@"settings_feedback"])
  {
    InfinitSettingsReportProblemController* controller = nil;
    if ([InfinitHostDevice iOS7])
      controller = segue.destinationViewController;
    else
      controller = ((UINavigationController*)segue.destinationViewController).viewControllers[0];
    controller.feedback_mode = YES;
  }
  else if ([segue.identifier isEqualToString:@"register_invitation_code_segue"])
  {
    InfinitLoginInvitationCodeController* dest_vc =
      (InfinitLoginInvitationCodeController*)segue.destinationViewController;
    dest_vc.login_mode = NO;
  }
}


@end
