//
//  InfinitWelcomePasswordViewController.m
//  Infinit
//
//  Created by Christopher Crone on 23/04/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitWelcomePasswordViewController.h"

#import "InfinitConstants.h"

@interface InfinitWelcomePasswordViewController ()

@property (nonatomic, weak) IBOutlet UIActivityIndicatorView* activity;
@property (nonatomic, weak) IBOutlet UIButton* back_button;
@property (nonatomic, weak) IBOutlet UIButton* forgot_button;
@property (nonatomic, weak) IBOutlet UIButton* facebook_button;
@property (nonatomic, weak) IBOutlet UIButton* login_button;
@property (nonatomic, weak) IBOutlet UITextField* password_field;
@property (nonatomic, weak) IBOutlet UIView* password_line;

@end

@implementation InfinitWelcomePasswordViewController

- (void)resetView
{
  [super resetView];
  self.password_field.text = @"";
  self.password_line.backgroundColor = self.normal_color;
  self.facebook_button.hidden = NO;
  [self setInputsEnabled:YES];
  [self.activity stopAnimating];
  self.login_button.hidden = NO;
}

- (void)setHide_facebook_button:(BOOL)hidden
{
  if (hidden)
  {
    [self setInfoText:NSLocalizedString(@"Account already registered for\nFacebook email address.",
                                        nil)];
    [self setInputsEnabled:YES];
    [self.activity stopAnimating];
    self.login_button.hidden = NO;
  }
  self.facebook_button.hidden = hidden;
}

#pragma mark - Text Field Delegate

- (IBAction)textDidChange:(id)sender
{
  if ([self passwordGood] || self.password_field.text.length == 0)
    self.password_line.backgroundColor = self.normal_color;
  self.forgot_button.hidden = !(self.password_field.text.length == 0);
}

- (IBAction)endedEditing:(id)sender
{
  [self tryLogin];
}

#pragma mark - Button Handling

- (IBAction)backTapped:(id)sender
{
  [self.delegate welcomePasswordBack:self];
}

- (void)tryLogin
{
  if (![self passwordGood])
  {
    [self shakeField:self.password_field andLine:self.password_line];
    return;
  }
  self.login_button.hidden = YES;
  [self.activity startAnimating];
  [self setInputsEnabled:NO];
  __weak InfinitWelcomePasswordViewController* weak_self = self;
  [self.delegate welcomePasswordLogin:self
                             password:self.password_field.text
                      completionBlock:^(InfinitStateResult* result)
  {
    if (weak_self == nil)
      return;
    InfinitWelcomePasswordViewController* strong_self = weak_self;
    [strong_self.activity stopAnimating];
    strong_self.login_button.hidden = NO;
    if (result.success)
    {
      [strong_self.delegate welcomePasswordDone:strong_self];
    }
    else
    {
      [strong_self setInfoText:[strong_self.delegate errorStringForGapStatus:result.status]];
      [strong_self shakeField:strong_self.password_field andLine:strong_self.password_line];
      strong_self.forgot_button.hidden = NO;
    }
    [strong_self setInputsEnabled:YES];
  }];
}

- (IBAction)loginTapped:(id)sender
{
  [self tryLogin];
}

- (IBAction)forgotTapped:(id)sender
{
  [[UIApplication sharedApplication] openURL:[NSURL URLWithString:kInfinitForgotPasswordURL]];
}

- (IBAction)facebookTapped:(id)sender
{
  [self setInputsEnabled:NO];
  self.login_button.hidden = YES;
  [self.activity startAnimating];
  [self.delegate welcomePasswordFacebook:self];
}

#pragma mark - Helpers

- (BOOL)passwordGood
{
  return (self.password_field.text.length >= 3);
}

- (void)setInputsEnabled:(BOOL)enabled
{
  [self.view endEditing:YES];
  self.password_field.enabled = enabled;
  self.login_button.enabled = enabled;
  self.back_button.enabled = enabled;
  self.facebook_button.enabled = enabled;
}

@end
