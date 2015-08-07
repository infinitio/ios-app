//
//  InfinitFeedbackManager.m
//  Infinit
//
//  Created by Christopher Crone on 04/06/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitFeedbackManager.h"

#import "AppDelegate.h"
#import "InfinitHomeFeedbackViewController.h"

@interface InfinitFeedbackManager () <InfinitHomeFeedbackViewProtocol,
                                      UIAlertViewDelegate,
                                      UINavigationControllerDelegate>

@property (atomic, readwrite) NSUInteger shake_number;
@property (atomic, readwrite) BOOL showing_feedback;
@property (nonatomic, readonly) InfinitHomeFeedbackViewController* feedback_controller;

@end

static InfinitFeedbackManager* _instance = nil;
static dispatch_once_t _instance_token = 0;

@implementation InfinitFeedbackManager

@synthesize feedback_controller = _feedback_controller;

#pragma mark - Init

- (instancetype)init
{
  NSCAssert(_instance == nil, @"Use sharedInstance.");
  if (self = [super init])
  {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didReceiveMemoryWarning)
                                                 name:UIApplicationDidReceiveMemoryWarningNotification 
                                               object:nil];
  }
  return self;
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

+ (instancetype)sharedInstance
{
  dispatch_once(&_instance_token, ^
  {
    _instance = [[self alloc] init];
  });
  return _instance;
}

#pragma mark - Shake Handling

- (void)gotShake:(UIEvent*)event
{
  if (self.showing_feedback)
    return;
  self.shake_number += 1;
  if (self.shake_number == 2)
  {
    self.showing_feedback = YES;
    NSString* title = NSLocalizedString(@"Everything OK?", @"shake to give feedback title");
    NSString* message = NSLocalizedString(@"If not, tap send feedback to let us know what's wrong.", nil);
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:title
                                                    message:message
                                                   delegate:self
                                          cancelButtonTitle:NSLocalizedString(@"Cancel", nil) 
                                          otherButtonTitles:NSLocalizedString(@"Send Feedback", nil), nil];
    [alert show];
  }
  else
  {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^
    {
      self.shake_number = 0;
    });
  }
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView*)alertView
clickedButtonAtIndex:(NSInteger)buttonIndex
{
  if (alertView.cancelButtonIndex == buttonIndex)
  {
    self.showing_feedback = NO;
  }
  else
  {
    AppDelegate* delegate = [UIApplication sharedApplication].delegate;
    [delegate.root_controller presentViewController:self.feedback_controller animated:YES completion:nil];
  }
}

#pragma mark - Lazy Loading

- (InfinitHomeFeedbackViewController*)feedback_controller
{
  if (_feedback_controller == nil)
  {
    UINib* nib = [UINib nibWithNibName:NSStringFromClass(InfinitHomeFeedbackViewController.class)
                                bundle:nil];
    _feedback_controller = [[nib instantiateWithOwner:self options:nil] firstObject];
    _feedback_controller.caller_delegate = self;
  }
  return _feedback_controller;
}

- (void)didReceiveMemoryWarning
{
  if (self.showing_feedback)
    return;
  _feedback_controller = nil;
}

#pragma mark - InfinitHomeFeedbackViewProtocol

- (void)feedbackViewControllerDidHide:(InfinitHomeFeedbackViewController*)sender
{
  self.showing_feedback = NO;
  self.shake_number = 0;
}

@end
