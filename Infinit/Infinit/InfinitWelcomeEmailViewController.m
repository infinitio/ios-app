//
//  InfinitWelcomeEmailViewController.m
//  Infinit
//
//  Created by Christopher Crone on 23/04/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitWelcomeEmailViewController.h"

#import "NSString+email.h"

@interface InfinitWelcomeEmailViewController () <UITextFieldDelegate>

@property (nonatomic, weak) IBOutlet UIButton* back_button;
@property (nonatomic, weak) IBOutlet UIButton* next_button;
@property (nonatomic, weak) IBOutlet UITextField* email_field;
@property (nonatomic, weak) IBOutlet UIButton* facebook_button;

@end

@implementation InfinitWelcomeEmailViewController

- (void)viewDidLoad
{
  [super viewDidLoad];
  self.view.translatesAutoresizingMaskIntoConstraints = NO;
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  self.next_button.enabled = [self inputsGood];
}

#pragma mark - Text Field Delegate

- (IBAction)textChanged:(id)sender
{
  self.next_button.enabled = [self inputsGood];
}

- (IBAction)endedEditing:(id)sender
{
  if (!self.email_field.text.isEmail)
    return;
  [self.email_field resignFirstResponder];
  [self.delegate welcomeEmailNext:self withEmail:self.email_field.text];
}

#pragma mark - Button Handling

- (IBAction)backTapped:(id)sender
{
  [self.delegate welcomeEmailBack:self];
}

- (IBAction)nextTapped:(id)sender
{
  [self.delegate welcomeEmailNext:self withEmail:self.email_field.text];
}

- (IBAction)facebookTapped:(id)sender
{
  
}

#pragma mark - Helpers

- (BOOL)inputsGood
{
  return (self.email_field.text.length && self.email_field.text.isEmail);
}

@end
