//
//  InfinitWelcomeLoginViewController.m
//  Infinit
//
//  Created by Christopher Crone on 24/04/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitWelcomeLoginViewController.h"

#import "InfinitApplicationSettings.h"
#import "InfinitConstants.h"

#import <Gap/InfinitColor.h>
#import <Gap/NSString+email.h>

@interface InfinitWelcomeLoginViewController () <UITextFieldDelegate>

@property (nonatomic, weak) IBOutlet UIActivityIndicatorView* activity;
@property (nonatomic, weak) IBOutlet UIButton* back_button;
@property (nonatomic, weak) IBOutlet UIButton* login_button;
@property (nonatomic, weak) IBOutlet UIButton* facebok_button;
@property (nonatomic, weak) IBOutlet UIButton* forgot_button;
@property (nonatomic, weak) IBOutlet UITextField* email_field;
@property (nonatomic, weak) IBOutlet UIView* email_line;
@property (nonatomic, weak) IBOutlet UITextField* password_field;
@property (nonatomic, weak) IBOutlet UIView* password_line;

@end

@implementation InfinitWelcomeLoginViewController

- (void)resetView
{
  [super resetView];
  self.email_field.text = @"";
  self.email_line.backgroundColor = self.normal_color;
  self.password_field.text = @"";
  self.password_line.backgroundColor = self.normal_color;
  [self setInputsEnabled:YES];
  [self.activity stopAnimating];
  self.login_button.hidden = NO;
}

#pragma mark - Text Field Delegate

- (IBAction)textDidChange:(id)sender
{
  if (sender == self.email_field)
  {
    if ([self emailGood] || self.email_field.text.length == 0)
      self.email_line.backgroundColor = self.normal_color;
  }
  else if (sender == self.password_field)
  {
    if ([self passwordGood] || self.password_field.text.length == 0)
      self.password_line.backgroundColor = self.normal_color;
    self.forgot_button.hidden = !(self.password_field.text.length == 0);
  }
}

- (IBAction)endedEditing:(id)sender
{
  if (sender == self.email_field)
  {
    [self.password_field becomeFirstResponder];
    if (![self emailGood])
    {
      self.email_line.backgroundColor = self.error_color;
      [self shakeField:self.email_field andLine:self.email_line];
    }
  }
  else if (sender == self.password_field)
  {
    if ([self passwordGood])
    {
      [self doLogin];
    }
    else
    {
      self.password_line.backgroundColor = self.error_color;
      [self shakeField:self.password_field andLine:self.password_line];
    }
  }
}

#pragma mark - Button Handling

- (void)doLogin
{
  if (![self emailGood])
  {
    self.email_line.backgroundColor = self.error_color;
    [self shakeField:self.email_field andLine:self.email_line];
    return;
  }
  if (![self passwordGood])
  {
    self.password_line.backgroundColor = self.error_color;
    [self shakeField:self.password_field andLine:self.password_line];
    return;
  }
  [self.activity startAnimating];
  self.login_button.hidden = YES;
  [self setInputsEnabled:NO];
  __weak InfinitWelcomeLoginViewController* weak_self = self;
  [self.delegate welcomeLogin:self
                        email:self.email_field.text
                     password:self.password_field.text
              completionBlock:^(InfinitStateResult* result)
  {
    if (weak_self == nil)
      return;
    InfinitWelcomeLoginViewController* strong_self = weak_self;
    [strong_self.activity stopAnimating];
    strong_self.login_button.hidden = NO;
    if (result.success)
    {
      [strong_self.delegate welcomeLoginDone:strong_self];
      [InfinitApplicationSettings sharedInstance].login_method = InfinitLoginEmail;
    }
    else
    {
      [strong_self shakeField:strong_self.email_field andLine:strong_self.email_line];
      strong_self.email_line.backgroundColor = self.error_color;
      [strong_self shakeField:strong_self.password_field andLine:strong_self.password_line];
      self.password_line.backgroundColor = self.error_color;
      [strong_self setErrorText:[strong_self.delegate errorStringForGapStatus:result.status]];
      if (result.status == gap_email_password_dont_match)
        strong_self.forgot_button.hidden = NO;
    }
    [strong_self setInputsEnabled:YES];
  }];
}

- (IBAction)backTapped:(id)sender
{
  [self.view endEditing:YES];
  [self.delegate welcomeLoginBack:self];
}

- (IBAction)loginTapped:(id)sender
{
  [self doLogin];
}

- (IBAction)facebookTapped:(id)sender
{
  [self setInputsEnabled:NO];
  self.login_button.hidden = YES;
  [self.activity startAnimating];
  [self.delegate welcomeLoginFacebook:self];
}

- (IBAction)forgotTapped:(id)sender
{
  [[UIApplication sharedApplication] openURL:[NSURL URLWithString:kInfinitForgotPasswordURL]];
}

#pragma mark - Helpers

- (BOOL)emailGood
{
  return self.email_field.text.infinit_isEmail;
}

- (BOOL)passwordGood
{
  return self.password_field.text.length >= 3;
}

- (void)setInputsEnabled:(BOOL)enabled
{
  [self.view endEditing:YES];
  self.login_button.enabled = enabled;
  self.facebok_button.enabled = enabled;
  self.forgot_button.enabled = enabled;
  self.email_field.enabled = enabled;
  self.password_field.enabled = enabled;
  self.back_button.enabled = enabled;
}

@end
