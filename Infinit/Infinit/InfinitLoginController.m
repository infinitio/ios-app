//
//  InfinitLoginController.m
//  Infinit
//
//  Created by Christopher Crone on 23/10/14.
//  Copyright (c) 2014 Christopher Crone. All rights reserved.
//

#import "InfinitLoginController.h"

#import <Gap/InfinitPeerTransactionManager.h>
#import <Gap/InfinitStateManager.h>
#import <Gap/InfinitStateResult.h>
#import <Gap/InfinitUserManager.h>

@implementation InfinitLoginController

- (void)viewDidLoad
{
  [super viewDidLoad];
  self.error.hidden = YES;
  UIGestureRecognizer* tapper =
    [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
  tapper.cancelsTouchesInView = NO;
  [self.view addGestureRecognizer:tapper];

  self.email.text = @"chris@infinit.io";
  self.password.text = @"password";
}

- (void)handleSingleTap:(UITapGestureRecognizer*)sender
{
  [self.view endEditing:YES];
}

- (IBAction)login:(id)sender
{
  [self.spinner startAnimating];
  self.spinner.hidden = NO;
  self.login.hidden = YES;
  self.login.enabled = NO;
  if (self.email.text.length == 0)
  {
    self.error.hidden = NO;
    self.error.text = NSLocalizedString(@"Enter an email address", nil);
    return;
  }
  if (self.password.text.length == 0)
  {
    self.error.hidden = NO;
    self.error.text = NSLocalizedString(@"Enter your password", nil);
    return;
  }
  [[InfinitStateManager sharedInstance] login:self.email.text
                                     password:self.password.text
                              performSelector:@selector(loginCallback:)
                                     onObject:self];
  [self.spinner stopAnimating];
  self.spinner.hidden = YES;
  self.login.hidden = NO;
  self.login.enabled = YES;
}

- (void)loginCallback:(InfinitStateResult*)result
{
  if (result.success)
  {
    [InfinitUserManager sharedInstance];
    [InfinitPeerTransactionManager sharedInstance];
    [self performSegueWithIdentifier:@"logged_in" sender:self];
  }
  else
  {
    self.error.text = [NSString stringWithFormat:@"Error: %d", result.status];
  }
}

//- Text Field Delegate ----------------------------------------------------------------------------

- (BOOL)textFieldShouldReturn:(UITextField*)textField
{
  if (textField == self.email)
    [self.password becomeFirstResponder];
  else if (textField == self.password)
    [self login:self];
  return NO;
}

- (void)animateTextField:(UITextField*)textField
                      up:(BOOL)up
{
  CGFloat dist = 60.0f;
  CGFloat duration = 0.3f;

  CGFloat movement = (up ? -dist : dist);

  [UIView beginAnimations:@"loginTextSlide" context:nil];
  [UIView setAnimationBeginsFromCurrentState:YES];
  [UIView setAnimationDuration:duration];
  self.view.frame = CGRectOffset(self.view.frame, 0, movement);
  [UIView commitAnimations];
}

- (void)textFieldDidBeginEditing:(UITextField*)textField
{
  [self animateTextField:textField up:YES];
}

- (void)textFieldDidEndEditing:(UITextField*)textField
{
  [self animateTextField:textField up:NO];
}

@end
