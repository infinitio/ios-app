//
//  InfinitQuotaOverlayViewController.m
//  Infinit
//
//  Created by Christopher Crone on 19/08/15.
//  Copyright © 2015 Infinit. All rights reserved.
//

#import "InfinitQuotaOverlayViewController.h"

#import "InfinitConstants.h"
#import "InfinitContactManager.h"
#import "InfinitTabBarController.h"

#import <Gap/InfinitAccountManager.h>
#import <Gap/InfinitStateManager.h>
#import <Gap/NSNumber+DataSize.h>

@interface InfinitQuotaOverlayViewController ()

@property (nonatomic) IBOutlet NSLayoutConstraint* button_spacing;
@property (nonatomic) IBOutlet UIButton* cancel_button;
@property (nonatomic) IBOutlet NSLayoutConstraint* cta_2_height;
@property (nonatomic) IBOutlet UIButton* cta_button_1;
@property (nonatomic) IBOutlet UIButton* cta_button_2;
@property (nonatomic) IBOutlet UILabel* details_label;
@property (nonatomic) IBOutlet UILabel* title_label;

@property (nonatomic) NSString* details_str;
@property BOOL invite_tapped;
@property BOOL show_status_bar;
@property BOOL single_cta;
@property (nonatomic) NSString* title_str;

@end

@implementation InfinitQuotaOverlayViewController

#pragma mark - Init

- (instancetype)init
{
  NSString* class_name = NSStringFromClass(self.class);
  if (self = [super initWithNibName:class_name bundle:nil])
  {}
  return self;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  CGFloat radius = floor(self.cta_button_1.bounds.size.height / 2.0f);
  self.cta_button_1.layer.cornerRadius = radius;
  self.cta_button_2.layer.cornerRadius = radius;
  self.cta_button_2.layer.borderColor = [UIColor whiteColor].CGColor;
  self.cta_button_2.layer.borderWidth = 1.0f;
}

- (void)viewWillAppear:(BOOL)animated
{
  if (![UIApplication sharedApplication].statusBarHidden)
  {
    self.show_status_bar = YES;
    [[UIApplication sharedApplication] setStatusBarHidden:YES
                                            withAnimation:UIStatusBarAnimationSlide];
  }
  else
  {
    self.show_status_bar = NO;
  }
  [super viewWillAppear:animated];
  self.cancel_button.titleLabel.text = self.cancel_button.titleLabel.text.uppercaseString;
  // WORKAROUND: Doesn't display title correctly on first show.
  self.title_label.text = self.title_str;
  self.details_label.text = self.details_str;
  [self _enableBothCTAButtons:!self.single_cta];
  self.invite_tapped = NO;
}

- (void)viewWillDisappear:(BOOL)animated
{
  [super viewWillDisappear:animated];
  [self.delegate quotaOverlayWantsClose:self];
  if (self.show_status_bar || self.invite_tapped)
  {
    [[UIApplication sharedApplication] setStatusBarHidden:NO
                                            withAnimation:UIStatusBarAnimationSlide];
  }
}

#pragma mark - Configure

- (void)configureForGhostDownloadLimit:(InfinitUser*)ghost
{
  [self _enableBothCTAButtons:NO];
  InfinitContactAddressBook* contact =
    [[InfinitContactManager sharedInstance] contactForUser:ghost];
  NSString* ghost_name = nil;
  if (contact.first_name.length)
    ghost_name = contact.first_name;
  else if (contact.fullname.length)
    ghost_name = contact.fullname;
  else
    ghost_name = ghost.fullname;
  self.title_str = NSLocalizedString(@"You’re a power sharer!", nil);
  self.details_str =
    [NSString localizedStringWithFormat:@"It looks like %@ has already received 2 transfers. In order to receive your files, %@ will need to install Infinit.", ghost_name, ghost_name];
}

- (void)configureForSendToSelfLimit
{
  [self _enableBothCTAButtons:YES];
  NSNumber* quota = [InfinitAccountManager sharedInstance].send_to_self_quota.quota;
  self.title_str = NSLocalizedString(@"Invite friends to get a free upgrade!", nil);
  self.details_str =
    [NSString localizedStringWithFormat:@"You've reached your monthly quota of %@ transfers to your own devices.", quota];
}

- (void)configureForTransferSizeLimit
{
  [self _enableBothCTAButtons:YES];
  NSString* size = @([InfinitAccountManager sharedInstance].transfer_size_limit).infinit_fileSize;
  self.title_str = NSLocalizedString(@"Invite friends to get a free upgrade!", nil);
  self.details_str =
    [NSString localizedStringWithFormat:@"Your account is currently limited to %@ transfers.", size];
}

#pragma mark - Button Handling

- (void)_upgradeTapped
{
  InfinitStateManager* manager = [InfinitStateManager sharedInstance];
  [manager webLoginTokenWithCompletionBlock:^(InfinitStateResult* result,
                                              NSString* token,
                                              NSString* email)
   {
     if (!result.success || !token.length)
       return;
     NSString* url_str =
     [kInfinitUpgradePlanURL stringByAppendingFormat:@"&login_token=%@&email=%@", token, email];
     [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url_str]];
   }];
  [self.delegate quotaOverlayWantsClose:self];
}

- (IBAction)cancelTapped:(id)sender
{
  [self.delegate quotaOverlayWantsClose:self];
}

- (IBAction)CTA1Tapped:(id)sender
{
  if (self.single_cta)
  {
    [self _upgradeTapped];
    return;
  }
  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
  {
    [[InfinitTabBarController currentTabBarController] showContactsScreen];
  }
  else
  {
    InfinitStateManager* manager = [InfinitStateManager sharedInstance];
    [manager webLoginTokenWithCompletionBlock:^(InfinitStateResult* result,
                                                NSString* token,
                                                NSString* email)
     {
       if (!result.success || !token.length)
         return;
       NSString* url_str =
       [kInfinitReferalInviteURL stringByAppendingFormat:@"&login_token=%@&email=%@", token, email];
       [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url_str]];
     }];
  }
  self.invite_tapped = YES;
  [self.delegate quotaOverlayWantsClose:self];
}

- (IBAction)CTA2Tapped:(id)sender
{
  [self _upgradeTapped];
}

#pragma mark - Helpers

- (void)_enableBothCTAButtons:(BOOL)enable
{
  self.single_cta = !enable;
  self.cta_button_2.hidden = !enable;
  self.cta_button_2.enabled = enable;
  self.cta_2_height.constant = enable ? self.cta_button_1.bounds.size.height : 0.0f;
  self.button_spacing.constant = enable ? 15.0f : 0.0f;
  NSString* cta_1_str = enable ? NSLocalizedString(@"INVITE FRIENDS", nil)
                               : NSLocalizedString(@"REMOVE THIS LIMIT", nil);
  NSString* cancel_str =
    enable ? NSLocalizedString(@"CANCEL", nil) : NSLocalizedString(@"OK", nil);
  [self.cta_button_1 setTitle:cta_1_str forState:UIControlStateNormal];
  [self.cancel_button setTitle:cancel_str forState:UIControlStateNormal];
}

@end
