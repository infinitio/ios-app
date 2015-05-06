//
//  InfinitWelcomeEmailViewController.m
//  Infinit
//
//  Created by Christopher Crone on 23/04/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitWelcomeEmailViewController.h"

#import <Gap/NSString+email.h>

@interface InfinitWelcomeEmailViewController () <UITextFieldDelegate>

@property (nonatomic, weak) IBOutlet UIActivityIndicatorView* activity;
@property (nonatomic, weak) IBOutlet UIButton* back_button;
@property (nonatomic, weak) IBOutlet UIButton* next_button;
@property (nonatomic, weak) IBOutlet UITextField* email_field;
@property (nonatomic, weak) IBOutlet UIView* email_line;
@property (nonatomic, weak) IBOutlet UIButton* facebook_button;

@end

@implementation InfinitWelcomeEmailViewController

- (void)viewDidLoad
{
  [super viewDidLoad];
  self.facebook_button.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
  self.facebook_button.titleLabel.numberOfLines = 2;
}

- (void)resetView
{
  [super resetView];
  self.email_field.text = @"";
  self.email_line.backgroundColor = self.normal_color;
  [self setInputsEnabled:YES];
  [self.activity stopAnimating];
  self.next_button.hidden = NO;
  self.facebook_button.hidden = NO;
}

- (void)gotEmailAccountType
{
  [self.activity stopAnimating];
  self.next_button.hidden = NO;
  [self setInputsEnabled:YES];
}

- (void)facebookNoAccount
{
  [self.activity stopAnimating];
  [self setInputsEnabled:YES];
  self.next_button.hidden = NO;
  [self setInfoText:NSLocalizedString(@"Looks like you don't have an\naccount. Enter email.", nil)];
  self.facebook_button.hidden = YES;
}

- (NSString*)email
{
  return self.email_field.text;
}

- (void)setEmail:(NSString*)email
{
  self.email_field.text = email;
}

#pragma mark - Text Field Delegate

- (IBAction)textChanged:(id)sender
{
  if (self.email_field.text.length == 0 || [self inputsGood])
    self.email_line.backgroundColor = self.normal_color;
}

- (IBAction)endedEditing:(id)sender
{
  [self doNext];
}

#pragma mark - Button Handling

- (void)doNext
{
  if ([self inputsGood])
  {
    self.next_button.hidden = YES;
    [self.activity startAnimating];
    [self setInputsEnabled:NO];
    __weak InfinitWelcomeEmailViewController* weak_self = self;
    [self.delegate welcomeEmailNext:self withEmail:self.email_field.text completionBlock:^
    {
      if (weak_self == nil)
        return;
      InfinitWelcomeEmailViewController* strong_self = weak_self;
      [strong_self setInputsEnabled:YES];
      [strong_self.activity stopAnimating];
      strong_self.next_button.hidden = NO;
    }];
  }
  else
  {
    self.email_line.backgroundColor = self.error_color;
    [self shakeField:self.email_field andLine:self.email_line];
  }
}

- (IBAction)backTapped:(id)sender
{
  [self.view endEditing:YES];
  [self.delegate welcomeEmailBack:self];
}

- (IBAction)nextTapped:(id)sender
{
  [self doNext];
}

- (IBAction)facebookTapped:(id)sender
{
  [self setInputsEnabled:NO];
  self.next_button.hidden = YES;
  [self.activity startAnimating];
  [self.delegate welcomeEmailFacebook:self];
}

#pragma mark - Helpers

- (BOOL)inputsGood
{
  return self.email_field.text.infinit_isEmail;
}

- (void)setInputsEnabled:(BOOL)enabled
{
  [self.view endEditing:YES];
  self.email_field.enabled = enabled;
  self.next_button.enabled = enabled;
  self.back_button.enabled = enabled;
  self.facebook_button.enabled = enabled;
}

@end
