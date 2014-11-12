//
//  InfinitLoginController.m
//  Infinit
//
//  Created by Christopher Crone on 23/10/14.
//  Copyright (c) 2014 Christopher Crone. All rights reserved.
//

#import "InfinitLoginController.h"

#import <Gap/InfinitStateManager.h>
#import <Gap/InfinitStateResult.h>

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
  self.login.hidden = YES;
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
  NSLog(@"xxx login tapped");
  [[InfinitStateManager sharedInstance] login:self.email.text
                                     password:self.password.text
                              performSelector:@selector(loginCallback:)
                                     onObject:self];
  [self.spinner stopAnimating];
  self.login.hidden = NO;
}

- (void)loginCallback:(InfinitStateResult*)result
{
  if (result.success)
  {
  }
  else
  {
    // XXX Handle login error
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
  CGFloat dist = 95.0f;
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
