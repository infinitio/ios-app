//
//  InfinitSettingsViewController.m
//  Infinit
//
//  Created by Christopher Crone on 19/01/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitSettingsViewController.h"

#import "InfinitApplicationSettings.h"
#import "InfinitColor.h"
#import "InfinitConstants.h"
#import "InfinitHostDevice.h"
#import "InfinitMetricsManager.h"
#import "InfinitSettingsCell.h"
#import "InfinitSettingsExpandedCell.h"
#import "InfinitSettingsReportProblemController.h"
#import "InfinitSettingsUserCell.h"

#import <Gap/InfinitConnectionManager.h>
#import <Gap/InfinitStateManager.h>
#import <Gap/InfinitStateResult.h>
#import <Gap/InfinitUserManager.h>

typedef NS_ENUM(NSUInteger, InfinitSettingsSections)
{
  InfinitSettingsSectionAccount = 0,
  InfinitSettingsSectionFeedback,
  InfinitSettingsSectionLogout,
#ifdef DEBUG
  InfinitSettingsSectionDebug,
#endif

  InfinitSettingsSectionCount,
};

typedef NS_ENUM(NSUInteger, InfinitAccountSettings)
{
  InfinitAccountSettingUser = 0,
  InfinitAccountSettingEdit,
  InfinitAccountSettingDevice,

  InfinitAccountSettingsCount
};

typedef NS_ENUM(NSUInteger, InfinitFeedbackSettings)
{
  InfinitFeedbackSettingRate = 0,
  InfinitFeedbackSettingFeedback,
  InfinitFeedbackSettingHelp,
  InfinitFeedbackSettingProblem,

  InfinitFeedbackSettingsCount,
};

typedef NS_ENUM(NSUInteger, InfinitLogoutSettings)
{
  InfinitLogoutSettingLogout = 0,

  InfinitLogoutSettingsCount,
};

typedef NS_ENUM(NSUInteger, InfinitDebugSettings)
{
  InfinitDebugSettingResetOnboarding = 0,

  InfinitDebugSettingsCount,
};

@interface InfinitSettingsViewController () <UIAlertViewDelegate,
                                             UITableViewDataSource,
                                             UITableViewDelegate>

@property (nonatomic, weak) IBOutlet UITableView* table_view;

@property (atomic, readwrite) BOOL logging_out;

@end

@implementation InfinitSettingsViewController
{
@private
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
  self.logging_out = NO;
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
  [self.table_view scrollRectToVisible:CGRectMake(0.0f, 0.0f, 1.0f, 1.0f) animated:NO];
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
    case InfinitSettingsSectionFeedback:
      return InfinitFeedbackSettingsCount;
    case InfinitSettingsSectionLogout:
      return InfinitLogoutSettingsCount;
#ifdef DEBUG
    case InfinitSettingsSectionDebug:
      return InfinitDebugSettingsCount;
#endif

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
      case InfinitAccountSettingDevice:
      {
        InfinitSettingsCell* cell = [self.table_view dequeueReusableCellWithIdentifier:_norm_cell_id 
                                                                          forIndexPath:indexPath];
        cell.icon_view.image = [UIImage imageNamed:@"icon-rename-device-iphone"];
        cell.title_label.text = NSLocalizedString(@"Rename device", nil);
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        res = cell;
        break;
      }
    }
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
      case InfinitFeedbackSettingHelp:
      {
        cell.icon_view.image = [UIImage imageNamed:@"icon-help"];
        cell.title_label.text = NSLocalizedString(@"Help", nil);
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
#ifdef DEBUG
  else if (indexPath.section == InfinitSettingsSectionDebug)
  {
    InfinitSettingsCell* cell = [self.table_view dequeueReusableCellWithIdentifier:_norm_cell_id
                                                                      forIndexPath:indexPath];
    switch (indexPath.row)
    {
      case InfinitDebugSettingResetOnboarding:
        cell.title_label.text = @"Reset onboarding";
        cell.icon_view.image = nil;
        cell.accessoryType = UITableViewCellAccessoryNone;
        break;
    }
    res = cell;
  }
#endif
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
#ifdef DEBUG
  else if (indexPath.section == InfinitSettingsSectionDebug)
  {
    return 50.0f;
  }
#endif
  return 0.0f;
}

- (void)tableView:(UITableView*)tableView
didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
  if (self.logging_out)
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
        break;
      }
      case InfinitAccountSettingDevice:
        [self performSegueWithIdentifier:@"settings_edit_device" sender:self];
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
        NSString* itunes_link =
          [kInfinitStoreRatingLink stringByReplacingOccurrencesOfString:@"APP_ID"
                                                             withString:kInfinitAppStoreId];
        if ([InfinitHostDevice iOSVersion] > 8.0)
        {
          itunes_link =
            [kInfinitStoreRatingLinkiOS8 stringByReplacingOccurrencesOfString:@"APP_ID"
                                                                   withString:kInfinitAppStoreId];
        }
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:itunes_link]];
        break;
      }
      case InfinitFeedbackSettingFeedback:
        [self performSegueWithIdentifier:@"settings_feedback" sender:self];
        [InfinitMetricsManager sendMetric:InfinitUIEventFeedbackOpen
                                   method:InfinitUIMethodSettingsMenu];
        break;
      case InfinitFeedbackSettingHelp:
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:kInfinitHelpURL]];
        [InfinitMetricsManager sendMetric:InfinitUIEventHelpOpen
                                   method:InfinitUIMethodSettingsMenu];
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
    self.logging_out = YES;
    __weak InfinitSettingsViewController* weak_self = self;
    [[InfinitStateManager sharedInstance] logoutWithCompletionBlock:^(InfinitStateResult* result)
    {
      if (weak_self == nil)
        return;
      InfinitSettingsViewController* strong_self = weak_self;
      strong_self.logging_out = NO;
      NSString* identifier = nil;
      if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        identifier = @"welcome_controller_id";
      else
        identifier = @"welcome_nav_controller_id";
      strong_self.view.window.rootViewController =
      [strong_self.storyboard instantiateViewControllerWithIdentifier:identifier];
    }];
  }
#ifdef DEBUG
  else if (indexPath.section == InfinitSettingsSectionDebug)
  {
    switch (indexPath.row)
    {
      case InfinitDebugSettingResetOnboarding:
        [[InfinitApplicationSettings sharedInstance] resetOnboarding];
        break;
    }
  }
#endif
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
}


@end
