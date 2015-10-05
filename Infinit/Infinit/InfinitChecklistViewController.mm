//
//  InfinitChecklistViewController.m
//  Infinit
//
//  Created by Chris Crone on 29/09/15.
//  Copyright © 2015 Infinit. All rights reserved.
//

#import "InfinitChecklistViewController.h"

#import "InfinitChecklistTableViewCell.h"
#import "InfinitConstants.h"
#import "InfinitContactAddressBook.h"
#import "InfinitContactManager.h"
#import "InfinitContactsViewController.h"
#import "InfinitFacebookManager.h"
#import "InfinitNonLocalizedString.h"

#import "UIImage+Rounded.h"

#import <Gap/InfinitAccountManager.h>
#import <Gap/InfinitAvatarManager.h>
#import <Gap/InfinitColor.h>
#import <Gap/InfinitExternalAccountsManager.h>
#import <Gap/InfinitStateManager.h>

#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>
#import <FBSDKShareKit/FBSDKShareKit.h>
#import <MobileCoreServices/MobileCoreServices.h>

#undef check
#import <elle/log.hh>

ELLE_LOG_COMPONENT("iOS.ChecklistOverlay");

@interface InfinitChecklistViewController () <FBSDKSharingDelegate,
                                              UIActionSheetDelegate,
                                              UIImagePickerControllerDelegate,
                                              UINavigationControllerDelegate,
                                              UITableViewDataSource,
                                              UITableViewDelegate>

@property (nonatomic) IBOutlet UIBarButtonItem* close_button;
@property (nonatomic) IBOutlet UITableView* table_view;

@property (nonatomic) UIImage* avatar;
@property (nonatomic, readonly) UIImagePickerController* picker;

@end

typedef NS_ENUM(NSUInteger, InfinitSelfQuotaOverlayRow)
{
  InfinitCheckListOverlayRow_Avatar = 0,
  InfinitCheckListOverlayRow_FBConnect,
  InfinitCheckListOverlayRow_FBPost,
  InfinitCheckListOverlayRow_TwitterPost,
  InfinitCheckListOverlayRow_Invite,

  InfinitCheckListOverlayRow_Count,
};

@implementation InfinitChecklistViewController

#pragma mark - Init

//UIViewController* root_controller =
//((AppDelegate*)[UIApplication sharedApplication].delegate).root_controller;
//UINavigationController* nav_controller =
//[self.storyboard instantiateViewControllerWithIdentifier:@"self_quota_nav_controller"];
//[root_controller presentViewController:nav_controller animated:YES completion:NULL];

- (void)viewDidLoad
{
  [super viewDidLoad];
  self.navigationController.navigationBar.tintColor =
    [InfinitColor colorFromPalette:InfinitPaletteColorBurntSienna];
  UIImage* back_image = [UIImage imageNamed:@"icon-back-white"];
  self.navigationController.navigationBar.backIndicatorImage = back_image;
  self.navigationController.navigationBar.backIndicatorTransitionMaskImage = back_image;
  self.navigationItem.backBarButtonItem =
    [[UIBarButtonItem alloc] initWithImage:back_image
                                     style:UIBarButtonItemStylePlain
                                    target:nil
                                    action:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  self.table_view.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
  NSDictionary* nav_bar_attrs = @{NSFontAttributeName: [UIFont fontWithName:@"SourceSansPro-Bold"
                                                                       size:17.0f],
                                  NSForegroundColorAttributeName: [InfinitColor colorWithRed:81
                                                                                       green:81
                                                                                        blue:73]};
  [self.navigationController.navigationBar setTitleTextAttributes:nav_bar_attrs];
  [self.table_view reloadData];
  if (self.settings)
    self.close_button.image = [UIImage imageNamed:@"icon-back-white"];
  else
    self.close_button.image = [UIImage imageNamed:@"icon-close"];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView*)tableView
 numberOfRowsInSection:(NSInteger)section
{
  NSUInteger referrals_count =
    [InfinitAccountManager sharedInstance].referral_actions.referrals.count;
  return InfinitCheckListOverlayRow_Count + referrals_count;
}

- (UITableViewCell*)tableView:(UITableView*)tableView
        cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
  NSString* identifer = nil;
  BOOL enabled = YES;
  InfinitAccountReferralActions* referral_actions =
    [InfinitAccountManager sharedInstance].referral_actions;
  InfinitExternalAccountsManager* manager = [InfinitExternalAccountsManager sharedInstance];
  switch (indexPath.row)
  {
    case InfinitCheckListOverlayRow_Avatar:
      identifer = @"checklist_cell_avatar";
      if (referral_actions.has_avatar)
        enabled = NO;
      break;
    case InfinitCheckListOverlayRow_FBConnect:
      identifer = @"checklist_cell_fb_connect";
      if (manager.have_facebook)
        enabled = NO;
      break;
    case InfinitCheckListOverlayRow_FBPost:
      identifer = @"checklist_cell_fb_post";
      if (referral_actions.facebook_posts > 0)
        enabled = NO;
      break;
    case InfinitCheckListOverlayRow_TwitterPost:
      identifer = @"checklist_cell_twitter_post";
      if (referral_actions.twitter_posts > 0)
        enabled = NO;
      break;
    case InfinitCheckListOverlayRow_Invite:
      identifer = @"checklist_cell_invite";
      break;

    default:
      identifer = @"checklist_cell_referral";
      enabled = NO;
      break;
  }
  if (identifer == nil)
    return nil;
  InfinitChecklistTableViewCell* cell =
    [tableView dequeueReusableCellWithIdentifier:identifer forIndexPath:indexPath];
  cell.enabled = enabled;
  if ([identifer isEqualToString:@"checklist_cell_referral"])
  {
    NSArray* referrals = [InfinitAccountManager sharedInstance].referral_actions.referrals;
    InfinitAccountReferral* referral = referrals[indexPath.row - InfinitCheckListOverlayRow_Count];
    InfinitContactAddressBook* contact =
      [[InfinitContactManager sharedInstance] contactForIdentifier:referral.identifier];
    if (contact && contact.avatar)
    {
      cell.icon = contact.avatar;
      dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
      {
        UIImage* icon = [contact.avatar infinit_circularMaskOfSize:cell.icon_size];
        dispatch_async(dispatch_get_main_queue(), ^
        {
          cell.icon = icon;
        });
      });
    }
    else
    {
      cell.icon = [UIImage imageNamed:@"icon-checklist-avatar"];
    }
    if (contact && contact.fullname.length)
      cell.title_str = contact.fullname;
    else
      cell.title_str = referral.identifier;
    NSString* status = nil;
    switch (referral.status)
    {
      case InfinitReferralStatus_Blocked:
        status = InfinitNonLocalizedString(@"Invitation blocked");
        break;
      case InfinitReferralStatus_Complete:
        if (referral.has_logged_in)
          status = InfinitNonLocalizedString(@"Joined");
        else
          status = InfinitNonLocalizedString(@"Invitation pending login");
        break;
      case InfinitReferralStatus_Pending:
        status = InfinitNonLocalizedString(@"Invitation pending register");
        break;

      default:
        break;
    }
    cell.description_str = status;
  }
  return cell;
}

#pragma mark - UITableViewDelegate

- (BOOL)tableView:(UITableView*)tableView
shouldHighlightRowAtIndexPath:(NSIndexPath*)indexPath
{
  InfinitChecklistTableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];
  return cell.enabled;
}

- (void)tableView:(UITableView*)tableView
didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
  switch (indexPath.row)
  {
    case InfinitCheckListOverlayRow_Avatar:
      ELLE_TRACE("%s: add avatar selected", self.description.UTF8String);
      [self addAvatar];
      break;
    case InfinitCheckListOverlayRow_FBConnect:
      ELLE_TRACE("%s: connect facebook selected", self.description.UTF8String);
      [self connectFacebookAccount];
      break;
    case InfinitCheckListOverlayRow_FBPost:
      ELLE_TRACE("%s: post facebook selected", self.description.UTF8String);
      [self postOnFacebook];
      break;
    case InfinitCheckListOverlayRow_TwitterPost:
      ELLE_TRACE("%s: post twitter selected", self.description.UTF8String);
      [self postOnTwitter];
      break;
    case InfinitCheckListOverlayRow_Invite:
      ELLE_TRACE("%s: invite selected", self.description.UTF8String);
      [self invite];
      break;

    default:
      break;
  }
}

#pragma mark - Avatar Picker

- (void)addAvatar
{
  UIActionSheet* actionSheet =
    [[UIActionSheet alloc] initWithTitle:nil
                                delegate:self
                       cancelButtonTitle:NSLocalizedString(@"Back", nil)
                  destructiveButtonTitle:nil
                       otherButtonTitles:NSLocalizedString(@"Take new photo", nil),
     NSLocalizedString(@"Choose a photo...", nil), nil];
  [actionSheet showInView:self.view];
}

- (void)presentImagePicker:(UIImagePickerControllerSourceType)sourceType
{
  if (self.picker == nil)
    _picker = [[UIImagePickerController alloc] init];
  self.picker.view.tintColor = [UIColor blackColor];
  self.picker.sourceType = sourceType;
  self.picker.mediaTypes = @[(NSString*)kUTTypeImage];
  self.picker.allowsEditing = YES;
  self.picker.delegate = self;
  if (sourceType == UIImagePickerControllerSourceTypeCamera)
  {
    self.picker.cameraDevice = UIImagePickerControllerCameraDeviceFront;
  }
  [self presentViewController:self.picker animated:YES completion:NULL];
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet*)actionSheet
didDismissWithButtonIndex:(NSInteger)buttonIndex
{
  switch (buttonIndex)
  {
    case 0:
      [self presentImagePicker:UIImagePickerControllerSourceTypeCamera];
      break;

    case 1:
      [self presentImagePicker:UIImagePickerControllerSourceTypeSavedPhotosAlbum];
      break;

    default:
      break;
  }
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerControllerDidCancel:(UIImagePickerController*)picker
{
  [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)imagePickerController:(UIImagePickerController*)picker
didFinishPickingMediaWithInfo:(NSDictionary*)info
{
  self.avatar = info[UIImagePickerControllerEditedImage];
  [[InfinitAvatarManager sharedInstance] setSelfAvatar:self.avatar];
  [self disableRow:InfinitCheckListOverlayRow_Avatar];
  [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Facebook

- (void)showAlertWithTitle:(NSString*)title
                   message:(NSString*)message
{
  dispatch_async(dispatch_get_main_queue(), ^
  {
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:title
                                                    message:message 
                                                   delegate:nil
                                          cancelButtonTitle:InfinitNonLocalizedString(@"OK")
                                          otherButtonTitles:nil];
    [alert show];
  });
}

- (void)connectFacebookAccount
{
  __weak InfinitChecklistViewController* weak_self = self;
  InfinitFacebookManager* manager = [InfinitFacebookManager sharedInstance];
  [manager.login_manager logInWithReadPermissions:kInfinitFacebookReadPermissions
                               fromViewController:self
                                          handler:^(FBSDKLoginManagerLoginResult* result,
                                                    NSError* error)
   {
     if (!error && !result.isCancelled)
     {
       if ([[FBSDKAccessToken currentAccessToken].permissions containsObject:@"email"])
       {
         NSString* token = [FBSDKAccessToken currentAccessToken].tokenString;
         [[InfinitStateManager sharedInstance] addFacebookAccount:token];
         [weak_self disableRow:InfinitCheckListOverlayRow_FBConnect];
       }
       else
       {
         NSString* title = InfinitNonLocalizedString(@"Unable to connect to Facebook");
         NSString* message =
           InfinitNonLocalizedString(@"You need to Infinit read permissions to your account.");
         [weak_self showAlertWithTitle:title message:message];
       }
       return;
     }
     NSString* message =
       error ? error.localizedDescription : InfinitNonLocalizedString(@"Facebook login cancelled.");
     [weak_self showAlertWithTitle:InfinitNonLocalizedString(@"Unable to connect with Facebook")
                           message:message];
   }];
}

- (void)postOnFacebook
{
  __weak InfinitChecklistViewController* weak_self = self;
  InfinitFacebookManager* manager = [InfinitFacebookManager sharedInstance];
  [manager.login_manager logInWithPublishPermissions:kInfinitFacebookWritePermissions
                                  fromViewController:self
                                             handler:^(FBSDKLoginManagerLoginResult* result,
                                                       NSError* error)
   {
     if (!error && !result.isCancelled)
     {
       if ([[FBSDKAccessToken currentAccessToken].permissions containsObject:@"publish_actions"])
       {
         FBSDKShareLinkContent* link = [[FBSDKShareLinkContent alloc] init];
         link.contentURL = [NSURL URLWithString:@"https://infinit.io?utm_source=facebook&utm_medium=checklist&utm_campaign=ios"];
         link.contentTitle = @"Infinit - Unlimited File Sharing";
         [FBSDKShareDialog showFromViewController:weak_self withContent:link delegate:weak_self];
       }
       else
       {
         NSString* title = InfinitNonLocalizedString(@"Unable to post to Facebook");
         NSString* message =
          InfinitNonLocalizedString(@"You need to grant permission for Infinit to publish on Faceobok.");
         [weak_self showAlertWithTitle:title message:message];
       }
       return;
     }
     NSString* message =
       error ? error.localizedDescription : InfinitNonLocalizedString(@"Facebook login cancelled.");
     [weak_self showAlertWithTitle:InfinitNonLocalizedString(@"Unable to connect with Facebook")
                           message:message];
   }];
}

#pragma mark - FBSDKSharingDelegate

- (void)sharer:(id<FBSDKSharing>)sharer
didCompleteWithResults:(NSDictionary*)results
{
  [self disableRow:InfinitCheckListOverlayRow_FBPost];
  [[InfinitStateManager sharedInstance] performSocialPostOnMedium:@"facebook"];
}

- (void)sharer:(id<FBSDKSharing>)sharer
didFailWithError:(NSError*)error
{
  [self showAlertWithTitle:InfinitNonLocalizedString(@"Unable to post to Facebook")
                   message:error.localizedDescription];
}

- (void)sharerDidCancel:(id<FBSDKSharing>)sharer
{}

#pragma mark - Twitter

- (void)postOnTwitter
{
  InfinitStateManager* manager = [InfinitStateManager sharedInstance];
  [manager webLoginTokenWithCompletionBlock:^(InfinitStateResult* result,
                                              NSString* token,
                                              NSString* email)
   {
     if (!result.success || !token.length)
       return;
     NSString* url_str =
       [kInfinitChecklistPostTwitterURL stringByAppendingFormat:@"&login_token=%@&email=%@",
        token, email];
       [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url_str]];
   }];
  [self disableRow:InfinitCheckListOverlayRow_TwitterPost];
}

#pragma mark - Invite

- (void)invite
{
  [self performSegueWithIdentifier:@"checklist_invite_segue" sender:self];
}

#pragma mark - Close Button

- (IBAction)closeTapped:(id)sender
{
  if (self.settings)
    [self performSegueWithIdentifier:@"settings_checklist_unwind" sender:self];
  else
    [self dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark - Disable Row

- (void)disableRow:(NSUInteger)row
{
  dispatch_async(dispatch_get_main_queue(), ^
  {
    NSIndexPath* index = [NSIndexPath indexPathForRow:row inSection:0];
    InfinitChecklistTableViewCell* cell = [self.table_view cellForRowAtIndexPath:index];
    cell.enabled = NO;
  });
}


@end
