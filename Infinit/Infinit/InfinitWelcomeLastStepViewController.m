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
@property (nonatomic, weak) IBOutlet UILabel* info_label;
@property (nonatomic, weak) IBOutlet UITextField* name_field;
@property (nonatomic, weak) IBOutlet UITextField* password_field;
@property (nonatomic, weak) IBOutlet UIButton* facebook_button;
@property (nonatomic, weak) IBOutlet UIButton* back_button;
@property (nonatomic, weak) IBOutlet UIButton* login_register_button;

@property (nonatomic, readonly) InfinitWelcomeLastStepBlock register_block;

@end

@implementation InfinitWelcomeLastStepViewController

- (void)viewDidLoad
{
  [super viewDidLoad];
  NSMutableAttributedString* info_text = [self.info_label.attributedText mutableCopy];
  NSMutableParagraphStyle* para = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
  para.alignment = NSTextAlignmentCenter;
  para.lineSpacing = 20.0f;
  [info_text addAttribute:NSParagraphStyleAttributeName
                    value:para
                    range:NSMakeRange(0, info_text.length)];
  self.info_label.attributedText = info_text;
  self.view.translatesAutoresizingMaskIntoConstraints = NO;
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  self.login_register_button.enabled = [self inputsGood];
}

#pragma mark - Text Field Delegate

- (BOOL)inputsGood
{
  if (self.password_field.text.length < 3 && self.name_field.text.length < 3)
    return NO;
  return YES;
}

- (IBAction)textChanged:(id)sender
{
  self.login_register_button.enabled = [self inputsGood];
}

- (IBAction)endedEditing:(id)sender
{
  if (sender == self.name_field && self.name_field.text.length >= 3)
  {
    [self.password_field becomeFirstResponder];
  }
  else if (sender == self.password_field && [self inputsGood])
  {
    [self loginRegisterTapped:self.password_field];
  }
}

#pragma mark - Button Handling

- (IBAction)backTapped:(id)sender
{
  [self.delegate welcomeLastStepBack:self];
}

- (IBAction)loginRegisterTapped:(id)sender
{
  [self inputsEnabled:NO];
  [self.activity startAnimating];
  [self.delegate welcomeLastStepRegister:self
                                    name:self.name_field.text
                                password:self.password_field.text 
                         completionBlock:self.register_block];
}

- (IBAction)facebookTapped:(id)sender
{
  [self inputsEnabled:NO];
  [self.delegate welcomeLastStepFacebookConnect:self completionBlock:self.register_block];
}

#pragma mark - Helpers

- (void)inputsEnabled:(BOOL)enabled
{
  [self.view endEditing:YES];
  self.name_field.enabled = enabled;
  self.password_field.enabled = enabled;
  self.facebook_button.enabled = enabled;
  self.login_register_button.enabled = enabled;
}

- (InfinitWelcomeLastStepBlock)register_block
{
  return ^(InfinitStateResult* result)
  {
    dispatch_async(dispatch_get_main_queue(), ^
    {
      [self.activity stopAnimating];
      if (result.success)
        [self.delegate welcomeLastStepDone:self];
      else
        self.info_label.text = [self.delegate welcomeLastStep:self errorFromStatus:result.status];
      [self inputsEnabled:YES];
    });
  };
}

@end
