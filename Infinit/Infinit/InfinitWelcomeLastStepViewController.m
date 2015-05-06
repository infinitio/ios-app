//
//  InfinitWelcomeLastStepViewController.m
//  Infinit
//
//  Created by Christopher Crone on 23/04/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitWelcomeLastStepViewController.h"

@interface InfinitWelcomeLastStepViewController () <UITextFieldDelegate>

@property (nonatomic, weak) IBOutlet UIActivityIndicatorView* activity;
@property (nonatomic, weak) IBOutlet UITextField* name_field;
@property (nonatomic, weak) IBOutlet UIView* name_line;
@property (nonatomic, weak) IBOutlet UITextField* password_field;
@property (nonatomic, weak) IBOutlet UIView* password_line;
@property (nonatomic, weak) IBOutlet UIButton* facebook_button;
@property (nonatomic, weak) IBOutlet UIButton* back_button;
@property (nonatomic, weak) IBOutlet UIButton* register_button;

@end

@implementation InfinitWelcomeLastStepViewController

- (void)viewDidLoad
{
  [super viewDidLoad];
  self.register_button.titleLabel.adjustsFontSizeToFitWidth = YES;
  self.facebook_button.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
  self.facebook_button.titleLabel.numberOfLines = 2;
}

- (void)resetView
{
  [super resetView];
  self.name_field.text = @"";
  self.name_line.backgroundColor = self.normal_color;
  self.password_field.text = @"";
  self.password_line.backgroundColor = self.normal_color;
  [self setInputsEnabled:YES];
  [self.activity stopAnimating];
  self.register_button.hidden = NO;
}

- (void)tryRegister
{
  [self setInputsEnabled:NO];
  self.register_button.hidden = YES;
  [self.activity startAnimating];
  __weak InfinitWelcomeLastStepViewController* weak_self = self;
  [self.delegate welcomeLastStepRegister:self
                                    name:self.name_field.text
                                password:self.password_field.text
                         completionBlock:^(InfinitStateResult* result)
  {
    if (weak_self == nil)
      return;
    InfinitWelcomeLastStepViewController* strong_self = weak_self;
    [strong_self.activity stopAnimating];
    if (result.success)
      [strong_self.delegate welcomeLastStepDone:strong_self];
    else
      [strong_self setErrorText:[strong_self.delegate errorStringForGapStatus:result.status]];
    [strong_self setInputsEnabled:YES];
    strong_self.register_button.hidden = NO;
  }];
}

#pragma mark - Public

- (void)setName:(NSString*)name
{
  self.name_field.text = name;
}

#pragma mark - Text Field Delegate

- (IBAction)textChanged:(id)sender
{
  if ([self nameGood] || self.name_field.text.length == 0)
    self.name_line.backgroundColor = self.normal_color;
  if ([self passwordGood] || self.password_field.text.length == 0)
    self.password_line.backgroundColor = self.normal_color;
}

- (IBAction)endedEditing:(id)sender
{
  if (sender == self.name_field)
  {
    [self.password_field becomeFirstResponder];
    if (![self nameGood])
    {
      [self shakeField:self.name_field andLine:self.name_line];
      self.name_line.backgroundColor = self.error_color;
    }
  }
  else if (sender == self.password_field)
  {
    if (![self passwordGood])
    {
      [self shakeField:self.password_field andLine:self.password_line];
      self.password_line.backgroundColor = self.error_color;
      return;
    }
    if ([self nameGood] && [self passwordGood])
      [self tryRegister];
  }
}

#pragma mark - Button Handling

- (IBAction)backTapped:(id)sender
{
  [self.delegate welcomeLastStepBack:self];
}

- (IBAction)registerTapped:(id)sender
{
  if (![self nameGood])
  {
    [self shakeField:self.name_field andLine:self.name_line];
    self.name_line.backgroundColor = self.error_color;
    return;
  }
  if (![self passwordGood])
  {
    [self shakeField:self.password_field andLine:self.password_line];
    self.password_line.backgroundColor = self.error_color;
    return;
  }
  [self tryRegister];
}

- (IBAction)facebookTapped:(id)sender
{
  [self setInputsEnabled:NO];
  [self.activity startAnimating];
  self.register_button.hidden = YES;
  [self.delegate welcomeLastStepFacebookConnect:self];
}

#pragma mark - Helpers

- (BOOL)nameGood
{
  return (self.name_field.text.length >= 3);
}

- (BOOL)passwordGood
{
  return (self.password_field.text.length >= 3);
}

- (void)setInputsEnabled:(BOOL)enabled
{
  [self.view endEditing:YES];
  self.name_field.enabled = enabled;
  self.password_field.enabled = enabled;
  self.facebook_button.enabled = enabled;
  self.register_button.enabled = enabled;
  self.back_button.enabled = enabled;
}

@end
