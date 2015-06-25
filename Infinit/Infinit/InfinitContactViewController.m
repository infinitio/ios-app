//
//  InfinitContactViewController.m
//  Infinit
//
//  Created by Christopher Crone on 31/01/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitContactViewController.h"

#import "InfinitHostDevice.h"
#import "InfinitInvitationOverlayViewController.h"
#import "InfinitMessagingManager.h"
#import "InfinitMessagingRecipient.h"
#import "InfinitMetricsManager.h"
#import "InfinitTabBarController.h"

#import <Gap/InfinitColor.h>
#import <Gap/InfinitStateManager.h>
#import <Gap/InfinitUserManager.h>

#import <Gap/NSString+email.h>
#import <Gap/NSString+PhoneNumber.h>

#import "UIImage+Rounded.h"

@interface InfinitContactViewController () <InfinitInvitationOverlayProtocol,
                                            UIGestureRecognizerDelegate>

@property (nonatomic, weak) IBOutlet UIImageView* avatar_view;
@property (nonatomic, weak) IBOutlet UIImageView* icon_view;
@property (nonatomic, weak) IBOutlet UILabel* name_label;
@property (nonatomic, weak) IBOutlet UIButton* send_invite_button;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint* send_center_constraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint* send_size_constraint;
@property (nonatomic, weak) IBOutlet UIButton* left_button;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint* left_size_constraint;
@property (nonatomic, weak) IBOutlet UIView* email_view;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint* email_height;
@property (nonatomic, weak) IBOutlet UILabel* email_address_label;
@property (nonatomic, weak) IBOutlet UIView* phone_view;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint* phone_height;
@property (nonatomic, weak) IBOutlet UILabel* phone_label;

@property (nonatomic, weak) IBOutlet NSLayoutConstraint* bar_width_constraint;

@property (nonatomic, strong) InfinitInvitationOverlayViewController* invitation_overlay;
@property (nonatomic, readonly) dispatch_once_t invitation_overlay_token;

@end

static UIImage* _avatar_favorite_icon = nil;
static UIImage* _avatar_infinit_icon = nil;
static UIImage* _button_favorite_icon = nil;
static UIImage* _button_invite_icon = nil;

static NSAttributedString* _invite_title = nil;
static NSAttributedString* _favorite_title = nil;
static NSAttributedString* _unfavorite_title = nil;

@implementation InfinitContactViewController

@synthesize invitation_overlay = _invitation_overlay;

#pragma mark - Init

- (void)viewDidLoad
{
  if (_avatar_favorite_icon == nil)
    _avatar_favorite_icon = [UIImage imageNamed:@"icon-badge-favorite-big"];
  if (_avatar_infinit_icon == nil)
    _avatar_infinit_icon = [UIImage imageNamed:@"icon-badge-infinit-big"];
  [super viewDidLoad];

  self.send_invite_button.layer.cornerRadius = self.send_invite_button.bounds.size.height / 2.0f;
  self.left_button.layer.cornerRadius = self.left_button.bounds.size.height / 2.0f;
  self.left_button.imageEdgeInsets = UIEdgeInsetsMake(0.0f, -8.0f, 0.0f, 0.0f);
  self.left_button.titleEdgeInsets = UIEdgeInsetsMake(0.0f, 0.0f, 0.0f, -2.0f);
  self.send_invite_button.imageEdgeInsets = UIEdgeInsetsMake(3.0f, -6.0f, 3.0f, 0.0f);
  self.send_invite_button.titleEdgeInsets = UIEdgeInsetsMake(0.0f, 0.0f, 0.0f, -5.0f);

  self.navigationController.interactivePopGestureRecognizer.enabled = YES;
  self.navigationController.interactivePopGestureRecognizer.delegate = self;

  self.left_button.titleLabel.adjustsFontSizeToFitWidth = YES;
  self.left_button.titleLabel.minimumScaleFactor = 0.25f;
  self.send_invite_button.titleLabel.adjustsFontSizeToFitWidth = YES;
  self.send_invite_button.titleLabel.minimumScaleFactor = 0.25f;
  if (_invite_title == nil)
  {
    UIFont* font = [UIFont fontWithName:@"SourceSansPro-Bold" size:14.0f];
    NSMutableParagraphStyle* para = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    para.alignment = NSTextAlignmentCenter;
    NSDictionary* favorite_attrs =
      @{NSFontAttributeName: font,
        NSForegroundColorAttributeName: [UIColor whiteColor],
        NSParagraphStyleAttributeName: para};
    _favorite_title = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"FAVORITE", nil)
                                                      attributes:favorite_attrs];
    _unfavorite_title =
      [[NSAttributedString alloc] initWithString:NSLocalizedString(@"UNFAVORITE",  nil)
                                      attributes:favorite_attrs];
    NSDictionary* invite_attrs =
      @{NSFontAttributeName: font,
        NSForegroundColorAttributeName: [InfinitColor colorWithRed:81 green:81 blue:73],
        NSParagraphStyleAttributeName: para};
    _invite_title = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"INVITE", nil)
                                                    attributes:invite_attrs];
  }
}

- (void)viewWillAppear:(BOOL)animated
{
  self.bar_width_constraint.constant = self.view.bounds.size.width - (2.0f * 45.0f);
  [self configureView];
  [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
  self.navigationController.interactivePopGestureRecognizer.enabled = NO;
  self.navigationController.interactivePopGestureRecognizer.delegate = nil;
  [super viewWillDisappear:animated];
  _invitation_overlay = nil;
  _invitation_overlay_token = 0;
}

- (IBAction)backButtonTapped:(id)sender
{
  [self.navigationController popViewControllerAnimated:YES];
}

- (void)configureView;
{
  self.navigationItem.title = self.contact.fullname;
  self.avatar_view.image =
    [self.contact.avatar infinit_circularMaskOfSize:self.avatar_view.bounds.size];
  CGFloat send_width = self.send_invite_button.titleLabel.attributedText.size.width + 10.0f;
  send_width = send_width < 100.0f ? 100.0f : send_width;
  send_width = send_width > 140.0f ? 140.0f : send_width;
  self.send_size_constraint.constant = send_width;
  if ([self.contact isKindOfClass:InfinitContactAddressBook.class])
  {
    InfinitContactAddressBook* contact_ab = (InfinitContactAddressBook*)self.contact;
    self.icon_view.hidden = YES;
    [self setLeftButtonHidden:NO];
    [self configureLeftButtonInvite];
    self.email_view.hidden = !(contact_ab.emails.count > 0);
    self.email_height.constant = contact_ab.emails.count > 0 ? 55.0f : 0.0f;
    self.phone_view.hidden =
      !(contact_ab.phone_numbers.count > 0) && [InfinitHostDevice canSendSMS];
    self.phone_height.constant = contact_ab.phone_numbers.count > 0 ? 55.0f : 0.0f;
    NSMutableString* email_str = [[NSMutableString alloc] init];
    NSUInteger count = 0;
    for (NSString* email in contact_ab.emails)
    {
      [email_str appendString:email];
      if (++count < contact_ab.emails.count)
        [email_str appendString:@", "];
    }
    NSMutableString* phone_str = [[NSMutableString alloc] init];
    count = 0;
    for (NSString* number in contact_ab.phone_numbers)
    {
      [phone_str appendString:number];
      if (++count < contact_ab.phone_numbers.count)
        [phone_str appendString:@", "];
    }
    self.email_address_label.text = email_str;
    self.phone_label.text = phone_str;
  }
  else if ([self.contact isKindOfClass:InfinitContactUser.class])
  {
    InfinitContactUser* contact_user = (InfinitContactUser*)self.contact;
    self.email_view.hidden = YES;
    self.phone_view.hidden = YES;
    if (contact_user.infinit_user.favorite || contact_user.infinit_user.is_self)
    {
      self.icon_view.image = _avatar_favorite_icon;
      [self setFavoriteButtonFavorite:YES];
    }
    else
    {
      self.icon_view.image = _avatar_infinit_icon;
      [self setFavoriteButtonFavorite:NO];
    }
    self.icon_view.hidden = NO;
    BOOL is_self = contact_user.infinit_user.is_self;
    [self setLeftButtonHidden:is_self];
  }
  self.name_label.text = self.contact.fullname;
}

- (void)configureLeftButtonInvite
{
  [self.left_button setAttributedTitle:_invite_title forState:UIControlStateNormal];
  self.left_button.layer.borderColor = [InfinitColor colorWithRed:81 green:81 blue:73].CGColor;
  self.left_button.layer.borderWidth = 1.0f;
  self.left_button.backgroundColor = [UIColor whiteColor];
  if (_button_invite_icon == nil)
    _button_invite_icon = [UIImage imageNamed:@"icon-invite-black"];
  [self.left_button setImage:_button_invite_icon forState:UIControlStateNormal];
  CGFloat width = self.left_button.titleLabel.attributedText.size.width + 10.0f;
  width = width < 105.0f ? 105.0f : width;
  width = width > 140.0f ? 140.0f : width;
  self.left_size_constraint.constant = width;
}

- (void)setLeftButtonHidden:(BOOL)hidden
{
  CGFloat send_width = self.send_size_constraint.constant;
  self.send_center_constraint.constant = hidden ? -floor(send_width / 2.0f) : 10.0f;
  self.left_button.hidden = hidden;
}

- (void)setFavoriteButtonFavorite:(BOOL)favorite
{
  self.left_button.layer.borderWidth = 0.0f;
  NSAttributedString* text = favorite ? _unfavorite_title : _favorite_title;
  [self.left_button setAttributedTitle:text forState:UIControlStateNormal];
  CGFloat width = self.left_button.titleLabel.attributedText.size.width + 40.0f;
  width = width < 115.0f ? 115.0f : width;
  width = width > 140.0f ? 140.0f : width;
  self.left_size_constraint.constant = width;
  if (favorite)
  {
    [self.left_button setImage:nil forState:UIControlStateNormal];
  }
  else
  {
    if (_button_favorite_icon == nil)
      _button_favorite_icon = [UIImage imageNamed:@"icon-favorite-white"];
    [self.left_button setImage:_button_favorite_icon
                       forState:UIControlStateNormal];
  }
}

#pragma mark - Button Handling

- (IBAction)sendButtonTapped:(id)sender
{
  InfinitTabBarController* tab_controller = (InfinitTabBarController*)self.tabBarController;
  [tab_controller showSendScreenWithContact:self.contact];
}

- (IBAction)leftButtonTapped:(id)sender
{
  if ([self.contact isKindOfClass:InfinitContactUser.class])
  {
    InfinitContactUser* contact_user = (InfinitContactUser*)self.contact;
    if (contact_user.infinit_user == nil)
      return;
    if (contact_user.infinit_user.is_self)
      return;
    UIImage* new_icon;
    if (contact_user.infinit_user.favorite)
    {
      new_icon = _avatar_infinit_icon;
      [self setFavoriteButtonFavorite:NO];
      [InfinitMetricsManager sendMetric:InfinitUIEventContactViewFavorite
                                 method:InfinitUIMethodRemove];
    }
    else
    {
      new_icon = _avatar_favorite_icon;
      [self setFavoriteButtonFavorite:YES];
      [InfinitMetricsManager sendMetric:InfinitUIEventContactViewFavorite
                                 method:InfinitUIMethodAdd];
    }

    [UIView transitionWithView:self.icon_view
                      duration:0.3f
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^
    {
      self.icon_view.image = new_icon;
    } completion:^(BOOL finished)
    {
      if (!finished)
        self.icon_view.image = new_icon;
    }];
    if (contact_user.infinit_user.favorite)
      [[InfinitUserManager sharedInstance] removeFavorite:contact_user.infinit_user];
    else
      [[InfinitUserManager sharedInstance] addFavorite:contact_user.infinit_user];
  }
  else if ([self.contact isKindOfClass:InfinitContactAddressBook.class])
  {
    [self showInvitationOverlay];
  }
}

- (void)showInvitationOverlay
{
  if (![self.contact isKindOfClass:InfinitContactAddressBook.class])
    return;
  InfinitContactAddressBook* contact_ab = (InfinitContactAddressBook*)self.contact;
  self.invitation_overlay.contact = contact_ab;
  self.view.userInteractionEnabled = NO;
  UIView* view = self.invitation_overlay.view;
  view.alpha = 0.0f;
  view.frame = [UIScreen mainScreen].bounds;
  [[UIApplication sharedApplication].keyWindow addSubview:view];
  [self.invitation_overlay awakeFromNib];
  [[UIApplication sharedApplication].keyWindow bringSubviewToFront:view];
  [UIView animateWithDuration:0.3f
                   animations:^
   {
     view.alpha = 1.0f;
   } completion:^(BOOL finished)
   {
     if (!finished)
       view.alpha = 1.0f;
   }];
}

- (void)removeInvitationOverlay
{
  UIView* view = self.invitation_overlay.view;
  if (view == nil)
    return;
  [UIView animateWithDuration:0.3f
                   animations:^
   {
     view.alpha = 0.0f;
   } completion:^(BOOL finished)
   {
     self.view.userInteractionEnabled = YES;
     [view removeFromSuperview];
   }];
}

#pragma mark - InfinitInvitationOverlayProtocol

- (void)invitationOverlayGotCancel:(InfinitInvitationOverlayViewController*)sender
{
  [self removeInvitationOverlay];
}

- (void)invitationOverlay:(InfinitInvitationOverlayViewController*)sender
             gotRecipient:(InfinitMessagingRecipient*)recipient
{
  [self removeInvitationOverlay];
  __weak InfinitContactViewController* weak_self = self;
  [[InfinitStateManager sharedInstance] plainInviteContact:recipient.identifier
                                           completionBlock:^(InfinitStateResult* result,
                                                             NSString* contact,
                                                             NSString* code,
                                                             NSString* url)
  {
    InfinitContactViewController* strong_self = weak_self;
    if (!result.success)
    {
      NSString* message = NSLocalizedString(@"This user is already on Infinit.", nil);
      [strong_self showAlertWithTitle:NSLocalizedString(@"User already on Infinit", nil)
                              message:message];
      [self removeInvitationOverlay];
      return;
    }
    if (recipient.method == InfinitMessageEmail)
    {
      NSString* message =
        NSLocalizedString(@"Your contact will receive an email from us inviting them to Infinit.", nil);
      [strong_self showAlertWithTitle:NSLocalizedString(@"Email sent!", nil) message:message];
      return;
    }
    else if (recipient.method == InfinitMessageNative || recipient.method == InfinitMessageWhatsApp)
    {
      NSString* message =
        [NSString stringWithFormat:NSLocalizedString(@"Hey %@. I want to send you files using Infinit. It's a free, unlimited file sharing app. You should download it here: %@", nil),
         recipient.name, url];
      [[InfinitMessagingManager sharedInstance] sendMessage:message
                                                toRecipient:recipient
                                            completionBlock:[self messageCompletionBlockForCode:code]];
    }
  }];
}

- (InfinitSendMessageCompletionBlock)messageCompletionBlockForCode:(NSString*)code
{
  __weak InfinitContactViewController* weak_self = self;
  return ^(InfinitMessagingRecipient* recipient, NSString* message, InfinitMessageStatus status)
  {
    InfinitContactViewController* strong_self = weak_self;
    [strong_self removeInvitationOverlay];
    BOOL success = status == InfinitMessageStatusSuccess ? YES : NO;
    gap_InviteMessageMethod method;
    switch (recipient.method)
    {
      case InfinitMessageNative:
        method = gap_invite_message_native;
        break;
      case InfinitMessageWhatsApp:
        method = gap_invite_message_whatsapp;
        break;
      default:
        return;
    }
    NSString* fail_message = @"";
    switch (status)
    {
      case InfinitMessageStatusCancel:
        fail_message = @"cancel";
        break;
      case InfinitMessageStatusFail:
        fail_message = @"fail";
        break;
      default:
        break;
    }
    [[InfinitStateManager sharedInstance] sendMetricInviteSent:success
                                                          code:code
                                                        method:method
                                                    failReason:fail_message];
    if (recipient.method == InfinitMessageNative && status != InfinitMessageStatusSuccess)
    {
      if ([recipient.identifier isKindOfClass:NSString.class])
      {
        [[InfinitStateManager sharedInstance] sendInvitation:recipient.identifier
                                                     message:message
                                                   ghostCode:code];
      }
    }
  };
}

#pragma mark - Lazy Loaders

- (InfinitInvitationOverlayViewController*)invitation_overlay
{
  dispatch_once(&_invitation_overlay_token, ^
  {
    _invitation_overlay = [[InfinitInvitationOverlayViewController alloc] init];
    _invitation_overlay.delegate = self;
  });
  return _invitation_overlay;
}

#pragma mark - Helpers

- (void)showAlertWithTitle:(NSString*)title
                   message:(NSString*)message
{
  UIAlertView* alert = [[UIAlertView alloc] initWithTitle:title
                                                  message:message
                                                 delegate:nil
                                        cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                        otherButtonTitles:nil];
  [alert show];
}

@end
