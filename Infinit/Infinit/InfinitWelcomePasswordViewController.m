//
//  InfinitWelcomePasswordViewController.m
//  Infinit
//
//  Created by Christopher Crone on 23/04/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitWelcomePasswordViewController.h"

@interface InfinitWelcomePasswordViewController ()

@property (nonatomic, weak) IBOutlet UIActivityIndicatorView* activity;
@property (nonatomic, weak) IBOutlet UILabel* info_label;
@property (nonatomic, weak) IBOutlet UITextField* password_field;
@property (nonatomic, weak) IBOutlet UIButton* back_button;
@property (nonatomic, weak) IBOutlet UIButton* login_button;

@end

@implementation InfinitWelcomePasswordViewController

- (void)viewDidLoad
{
  [super viewDidLoad];
  self.login_button.enabled = [self inputsGood];
  self.view.translatesAutoresizingMaskIntoConstraints = NO;
}

#pragma mark - Text Field Delegate

- (IBAction)textChanged:(id)sender
{
  self.login_button.enabled = [self inputsGood];
}

- (IBAction)endedEditing:(id)sender
{
  if ([self inputsGood])
    [self loginTapped:self.password_field];
}

#pragma mark - Button Handling

- (IBAction)backTapped:(id)sender
{
  [self.delegate welcomePasswordBack:self];
}

- (IBAction)loginTapped:(id)sender
{
  [self.activity startAnimating];
  [self setInputsEnabled:NO];
  [self.delegate welcomePasswordLogin:self
                             password:self.password_field.text 
                      completionBlock:^(InfinitStateResult* result)
  {
    [self.activity stopAnimating];
    if (result.success)
    {
      [self.delegate welcomePasswordDone:self];
    }
    else
    {
      self.info_label.text = [self.delegate welcomePassword:self errorFromStatus:result.status];
    }
    [self setInputsEnabled:YES];
  }];
}

#pragma mark - Helpers

- (BOOL)inputsGood
{
  return (self.password_field.text.length >= 3);
}

- (void)setInputsEnabled:(BOOL)enabled
{
  [self.view endEditing:YES];
  self.password_field.enabled = enabled;
  self.login_button.enabled = enabled;
  self.back_button.enabled = enabled;
}

@end
