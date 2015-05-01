//
//  InfinitSettingsReportProblemController.m
//  Infinit
//
//  Created by Christopher Crone on 20/01/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitSettingsReportProblemController.h"

#import "InfinitColor.h"
#import "InfinitHostDevice.h"

#import <Gap/InfinitCrashReporter.h>

@interface InfinitSettingsReportProblemController () <UITextViewDelegate,
                                                      UIAlertViewDelegate>

@property (nonatomic, weak) IBOutlet UIBarButtonItem* send_button;
@property (nonatomic, weak) IBOutlet UITextView* text_view;

@end

@implementation InfinitSettingsReportProblemController
{
@private
  NSString* _place_holder_text;
}

#pragma mark - Init

- (void)viewDidLoad
{
  [super viewDidLoad];
  NSDictionary* nav_bar_attrs = @{NSFontAttributeName: [UIFont fontWithName:@"SourceSansPro-Bold"
                                                                       size:17.0f],
                                  NSForegroundColorAttributeName: [InfinitColor colorWithRed:81
                                                                                       green:81
                                                                                        blue:73]};
  [self.navigationController.navigationBar setTitleTextAttributes:nav_bar_attrs];
  self.text_view.textContainerInset = UIEdgeInsetsMake(15.0f, 15.0f, 15.0f, 15.0f);
  if (self.feedback_mode)
  {
    self.navigationItem.title = NSLocalizedString(@"FEEDBACK", nil);
    _place_holder_text = NSLocalizedString(@"Write your feedback here...", nil);
  }
  else
  {
    self.navigationItem.title = NSLocalizedString(@"REPORT A PROBLEM", nil);
    _place_holder_text = NSLocalizedString(@"Explain your problem here...", nil);
  }
  self.text_view.text = _place_holder_text;
  UITapGestureRecognizer* tap =
    [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
  [self.view addGestureRecognizer:tap];
  self.send_button.enabled = NO;
}

- (void)dismissKeyboard
{
  [self.view endEditing:YES];
}

#pragma mark - Text View

- (BOOL)textViewShouldBeginEditing:(UITextView*)textView
{
  NSMutableString* res = [NSMutableString stringWithString:textView.text];
  NSRange range = [res rangeOfString:_place_holder_text];
  if (range.location != NSNotFound)
    [res deleteCharactersInRange:range];
  textView.text = res;
  textView.textColor = [InfinitColor colorWithGray:42];
  return YES;
}

- (void)textViewDidEndEditing:(UITextView*)textView
{
  if (textView.text.length == 0)
  {
    textView.text = _place_holder_text;
    textView.textColor = [InfinitColor colorWithGray:177];
    self.send_button.enabled = NO;
  }
  else
  {
    self.send_button.enabled = YES;
  }
}

- (void)textViewDidChange:(UITextView*)textView
{
  if (textView.text.length > 0 &&
      [textView.text rangeOfString:_place_holder_text].location == NSNotFound)
  {
    self.send_button.enabled = YES;
  }
  else
  {
    self.send_button.enabled = NO;
  }
}

#pragma mark - Button Handling

- (void)goBack
{
  [self dismissKeyboard];
  if ([InfinitHostDevice iOS7])
  {
    [self.navigationController popViewControllerAnimated:YES];
  }
  else
  {
    [self.navigationController.navigationController popToRootViewControllerAnimated:YES];
  }
  self.text_view.text = _place_holder_text;
}

- (IBAction)backButtonTapped:(id)sender
{
  [self goBack];
}

- (IBAction)sendButtonTapped:(id)sender
{
  UIAlertView* alert = nil;
  if (self.feedback_mode)
  {
    alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Thanks!", nil)
                                       message:NSLocalizedString(@"Thanks for taking the time to give us feedback.", nil)
                                      delegate:self
                             cancelButtonTitle:NSLocalizedString(@"OK", nil)
                             otherButtonTitles:nil];
  }
  else
  {
    alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Thanks!", nil)
                                       message:NSLocalizedString(@"Thanks for reporting the problem, we'll get back to you as soon as we can.", nil)
                                      delegate:self
                             cancelButtonTitle:NSLocalizedString(@"OK", nil)
                             otherButtonTitles:nil];
  }
  [alert show];
  [[InfinitCrashReporter sharedInstance] reportAProblem:self.text_view.text file:@""];
}

- (void)alertViewCancel:(UIAlertView*)alertView
{
  [self goBack];
}

- (void)alertView:(UIAlertView*)alertView
clickedButtonAtIndex:(NSInteger)buttonIndex
{
  [self goBack];
}

@end
