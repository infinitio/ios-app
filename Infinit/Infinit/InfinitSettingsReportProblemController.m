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
#import "InfinitTabBarController.h"

#import <Gap/InfinitCrashReporter.h>

@interface InfinitSettingsReportProblemController () <UITextViewDelegate,
                                                      UIAlertViewDelegate>

@property (nonatomic, weak) IBOutlet UIButton* send_button;
@property (nonatomic, weak) IBOutlet UITextView* text_view;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint* text_view_height;

@end

@implementation InfinitSettingsReportProblemController
{
@private
  NSString* _report_problem_placeholder;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  if ([InfinitHostDevice smallScreen])
  {
    self.text_view_height.constant = 150.0f;
  }
  self.text_view.textContainerInset = UIEdgeInsetsMake(15.0f, 15.0f, 15.0f, 15.0f);
  self.send_button.titleEdgeInsets =
    UIEdgeInsetsMake(0.0f,
                     - self.send_button.imageView.frame.size.width,
                     0.0f,
                     self.send_button.imageView.frame.size.width);
  self.send_button.imageEdgeInsets =
    UIEdgeInsetsMake(0.0f,
                     self.send_button.titleLabel.frame.size.width + 10.0f,
                     0.0f,
                     - (self.send_button.titleLabel.frame.size.width + 10.0f));
  _report_problem_placeholder = NSLocalizedString(@"Explain your problem here...", nil);
  self.text_view.text = _report_problem_placeholder;
  UITapGestureRecognizer* tap =
    [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
  [self.view addGestureRecognizer:tap];
}

- (void)viewWillAppear:(BOOL)animated
{
  [((InfinitTabBarController*)self.tabBarController) setTabBarHidden:YES animated:YES];
  [super viewWillAppear:animated];
}

- (void)dismissKeyboard
{
  [self.text_view resignFirstResponder];
}

#pragma mark - Text View

- (BOOL)textViewShouldBeginEditing:(UITextView*)textView
{
  NSMutableString* res = [NSMutableString stringWithString:textView.text];
  NSRange range = [res rangeOfString:_report_problem_placeholder];
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
    textView.text = _report_problem_placeholder;
    textView.textColor = [InfinitColor colorWithGray:177];
  }
}

#pragma mark - Button Handling

- (IBAction)backButtonTapped:(id)sender
{
  [self.navigationController popViewControllerAnimated:YES];
  [((InfinitTabBarController*)self.tabBarController) setTabBarHidden:NO animated:NO];
}

- (IBAction)sendButtonTapped:(id)sender
{
  UIAlertView* alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Thanks!", nil)
                                                  message:NSLocalizedString(@"Thanks for reporting the problem, we'll get back to you as soon as we can.", nil)
                                                 delegate:self
                                        cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                        otherButtonTitles:nil];
  [alert show];
  [[InfinitCrashReporter sharedInstance] reportAProblem:self.text_view.text file:@""];
}

- (void)alertViewCancel:(UIAlertView*)alertView
{
  [self.navigationController popViewControllerAnimated:YES];
  self.text_view.text = _report_problem_placeholder;
  [((InfinitTabBarController*)self.tabBarController) setTabBarHidden:NO animated:NO];
}

- (void)alertView:(UIAlertView*)alertView
clickedButtonAtIndex:(NSInteger)buttonIndex
{
  [self.navigationController popViewControllerAnimated:YES];
  self.text_view.text = _report_problem_placeholder;
  [((InfinitTabBarController*)self.tabBarController) setTabBarHidden:NO animated:NO];
}

@end
