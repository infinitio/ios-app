//
//  InfinitLoginInvitationCodeController.m
//  Infinit
//
//  Created by Christopher Crone on 02/03/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitLoginInvitationCodeController.h"

#import "InfinitColor.h"
#import "InfinitHostDevice.h"

#import <Gap/InfinitStateManager.h>
#import <Gap/InfinitStateResult.h>

@interface InfinitLoginInvitationCodeController () <UIAlertViewDelegate,
                                                    UITextFieldDelegate>

@property (nonatomic, weak) IBOutlet UIActivityIndicatorView* activity_indicator;
@property (nonatomic, weak) IBOutlet UITextField* code_field;
@property (nonatomic, weak) IBOutlet UILabel* error_label;
@property (nonatomic, weak) IBOutlet UIView* top_view;

@property (nonatomic, weak) IBOutlet UIView* line_1;
@property (nonatomic, weak) IBOutlet UIView* line_2;
@property (nonatomic, weak) IBOutlet UIView* line_3;
@property (nonatomic, weak) IBOutlet UIView* line_4;
@property (nonatomic, weak) IBOutlet UIView* line_5;

@property (nonatomic) NSArray* lines;

@end

static NSDictionary* _attrs = nil;

@implementation InfinitLoginInvitationCodeController

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  _lines = @[self.line_1, self.line_2, self.line_3, self.line_4, self.line_5];
  [self setLineColor:[InfinitColor colorWithGray:151]];
  if (_attrs == nil)
  {
    _attrs = @{NSFontAttributeName: [UIFont fontWithName:@"Monaco" size:36.0f],
               NSForegroundColorAttributeName: [InfinitColor colorWithRed:81 green:81 blue:73],
               NSKernAttributeName: @13.0f};
  }
  self.code_field.tintColor = [InfinitColor colorWithRed:81 green:81 blue:73];
  self.code_field.defaultTextAttributes = _attrs;
  NSDictionary* nav_bar_attrs = @{NSFontAttributeName: [UIFont fontWithName:@"SourceSansPro-Bold"
                                                                       size:17.0f],
                                  NSForegroundColorAttributeName: [InfinitColor colorWithRed:81
                                                                                       green:81
                                                                                        blue:73]};
  [self.navigationController.navigationBar setTitleTextAttributes:nav_bar_attrs];
  self.navigationController.navigationBar.tintColor =
    [InfinitColor colorFromPalette:InfinitPaletteColorBurntSienna];
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  self.navigationController.navigationBarHidden = self.login_mode;
  self.code_field.text = @"";
  self.top_view.hidden = !self.login_mode;
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(keyboardWillShow:)
                                               name:UIKeyboardWillShowNotification
                                             object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
  [super viewWillDisappear:animated];
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Text Field Delegate

- (BOOL)textField:(UITextField*)textField
shouldChangeCharactersInRange:(NSRange)range
replacementString:(NSString*)string
{
  return (textField.text.length < 5 || string.length == 0);
}

- (IBAction)textChanged:(UITextField*)sender
{
  if (sender.text.length == 5)
  {
    [self.activity_indicator startAnimating];
    self.code_field.enabled = NO;
    [self dismissKeyboard:nil];
    NSString* code =
      [self.code_field.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    [[InfinitStateManager sharedInstance] useGhostCode:code.lowercaseString
                                       performSelector:@selector(checkCodeCallback:)
                                              onObject:self];
  }
}

- (IBAction)dismissKeyboard:(UITapGestureRecognizer*)sender
{
  [self.code_field resignFirstResponder];
  [UIView animateWithDuration:0.2f
                   animations:^
  {
    self.view.frame = CGRectMake(0.0f, 0.0f,
                                 self.view.frame.size.width, self.view.frame.size.height);
  }];
}

#pragma mark - Button Handling

- (IBAction)skipTapped:(id)sender
{
  [self showHomeScreen];
}

- (IBAction)backTapped:(id)sender
{
  [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Keyboard

- (void)keyboardWillShow:(NSNotification*)notification
{
  CGFloat delta = -50.0f;
  [UIView animateWithDuration:0.5f
                        delay:0.0f
                      options:UIViewAnimationOptionCurveEaseInOut
                   animations:^
   {
     self.view.frame = CGRectMake(0.0f, delta,
                                  self.view.frame.size.width, self.view.frame.size.height);
   } completion:^(BOOL finished)
   {
     if (!finished)
     {
       self.view.frame = CGRectMake(0.0f, delta,
                                    self.view.frame.size.width, self.view.frame.size.height);
     }
   }];
}

#pragma mark - Helpers

- (void)setLineColor:(UIColor*)color
{
  for (UIView* line in self.lines)
    line.backgroundColor = color;
}

- (void)showHomeScreen
{
  UIStoryboard* storyboard =
  [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
  UIViewController* view_controller =
    [storyboard instantiateViewControllerWithIdentifier:@"tab_bar_controller"];
  [self presentViewController:view_controller animated:YES completion:nil];
}

#pragma mark - Code Callback

- (void)alertView:(UIAlertView*)alertView
didDismissWithButtonIndex:(NSInteger)buttonIndex
{
  [self.navigationController popViewControllerAnimated:YES];
}

- (void)alertViewCancel:(UIAlertView*)alertView
{
  [self.navigationController popViewControllerAnimated:YES];
}

- (void)checkCodeCallback:(InfinitStateResult*)result
{
  [self.activity_indicator stopAnimating];
  self.code_field.enabled = YES;
  self.error_label.hidden = YES;
  if (result.success)
  {
    if (self.login_mode)
    {
      [self showHomeScreen];
    }
    else
    {
      NSString* message = NSLocalizedString(@"Check your home screen for your transaction.", nil);
      UIAlertView* alert =
        [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Code added!", nil)
                                   message:message
                                  delegate:self
                         cancelButtonTitle:NSLocalizedString(@"OK", nil)
                         otherButtonTitles:nil];
      [alert show];
    }
  }
  else
  {
    self.error_label.text = NSLocalizedString(@"Invalid code.", nil);
    self.error_label.hidden = NO;
  }
}

@end
