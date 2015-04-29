//
//  InfinitHomeFeedbackViewController.m
//  Infinit
//
//  Created by Christopher Crone on 05/02/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitHomeFeedbackViewController.h"

#import "InfinitHostDevice.h"

#import <Gap/InfinitColor.h>
#import <Gap/InfinitCrashReporter.h>

@interface InfinitHomeFeedbackViewController () <UITextViewDelegate,
                                                 UIAlertViewDelegate>

@property (nonatomic, weak) IBOutlet UIBarButtonItem* send_button;
@property (nonatomic, weak) IBOutlet UITextView* text_view;

@end

@implementation InfinitHomeFeedbackViewController
{
@private
  NSString* _feedback_placeholder;
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
  [self.navigationBar setTitleTextAttributes:nav_bar_attrs];
  self.text_view.textContainerInset = UIEdgeInsetsMake(15.0f, 15.0f, 15.0f, 15.0f);
  _feedback_placeholder = NSLocalizedString(@"Write your feedback here...", nil);
  self.text_view.text = _feedback_placeholder;
  UITapGestureRecognizer* tap =
    [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
  [self.view addGestureRecognizer:tap];
  self.send_button.enabled = NO;
}

- (void)dismissKeyboard
{
  [self.text_view resignFirstResponder];
}

#pragma mark - Text View

- (BOOL)textViewShouldBeginEditing:(UITextView*)textView
{
  NSMutableString* res = [NSMutableString stringWithString:textView.text];
  NSRange range = [res rangeOfString:_feedback_placeholder];
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
    textView.text = _feedback_placeholder;
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
      [textView.text rangeOfString:_feedback_placeholder].location == NSNotFound)
  {
    self.send_button.enabled = YES;
  }
  else
  {
    self.send_button.enabled = NO;
  }
}

#pragma mark - Button Handling

- (IBAction)backButtonTapped:(id)sender
{
  [self dismissKeyboard];
  [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)sendButtonTapped:(id)sender
{
  UIAlertView* alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Thanks!", nil)
                                                  message:NSLocalizedString(@"Thanks for taking the time to give us feedback.", nil)
                                                 delegate:self
                                        cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                        otherButtonTitles:nil];
  [alert show];
  [[InfinitCrashReporter sharedInstance] reportAProblem:self.text_view.text file:@""];
}

- (void)alertViewCancel:(UIAlertView*)alertView
{
  [self dismissKeyboard];
  [self dismissViewControllerAnimated:YES completion:nil];
  self.text_view.text = _feedback_placeholder;
}

- (void)alertView:(UIAlertView*)alertView
clickedButtonAtIndex:(NSInteger)buttonIndex
{
  [self dismissKeyboard];
  [self dismissViewControllerAnimated:YES completion:nil];
  self.text_view.text = _feedback_placeholder;
}
@end
