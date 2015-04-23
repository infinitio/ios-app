//
//  InfinitWelcomeViewController.m
//  Infinit
//
//  Created by Christopher Crone on 23/04/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitWelcomeViewController.h"

#import "InfinitColor.h"
#import "InfinitHostDevice.h"
#import "InfinitWelcomeCodeViewController.h"
#import "InfinitWelcomeEmailViewController.h"
#import "InfinitWelcomeInvitedViewController.h"
#import "InfinitWelcomeLandingViewController.h"
#import "InfinitWelcomeLastStepViewController.h"
#import "InfinitWelcomePasswordViewController.h"

@interface InfinitWelcomeViewController () <InfinitWelcomeCodeProtocol,
                                            InfinitWelcomeEmailProtocol,
                                            InfinitWelcomeInvitedProtocol,
                                            InfinitWelcomeLandingProtocol,
                                            InfinitWelcomeLastStepProtocol,
                                            InfinitWelcomePasswordProtocol>

@property (nonatomic, weak) IBOutlet UIImageView* balloon_view;
@property (nonatomic, weak) IBOutlet UIView* content_view;

@property (nonatomic, strong) InfinitWelcomeCodeViewController* code_controller;
@property (nonatomic, strong) InfinitWelcomeEmailViewController* email_controller;
@property (nonatomic, strong) InfinitWelcomeInvitedViewController* invited_controller;
@property (nonatomic, strong) InfinitWelcomeLandingViewController* landing_controller;
@property (nonatomic, strong) InfinitWelcomeLastStepViewController* last_step_controller;
@property (nonatomic, strong) InfinitWelcomePasswordViewController* password_controller;

@property (nonatomic, weak) UIViewController* current_controller;

@end

@implementation InfinitWelcomeViewController

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
  if (self.current_controller != _code_controller)
    _code_controller = nil;
  if (self.current_controller != _email_controller)
    _email_controller = nil;
  if (self.current_controller != _invited_controller)
    _invited_controller = nil;
  if (self.current_controller != _landing_controller)
    _landing_controller = nil;
  if (self.current_controller != _last_step_controller)
    _last_step_controller = nil;
  if (self.current_controller != _password_controller)
    _password_controller = nil;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  _current_controller = nil;
  [self showViewController:self.landing_controller animated:NO reverse:NO];
  [self.balloon_view addMotionEffect:[self balloonParallax]];
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  [[UIApplication sharedApplication] setStatusBarHidden:YES];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(keyboardWillShow:)
                                               name:UIKeyboardWillShowNotification
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(keyboardWillHide:)
                                               name:UIKeyboardWillHideNotification
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(backgroundedApp)
                                               name:UIApplicationDidEnterBackgroundNotification
                                             object:nil];
}

- (void)backgroundedApp
{
  [self hideKeyboardWithAnimation:NO];
}

- (IBAction)viewTapped:(id)sender
{
  [self hideKeyboardWithAnimation:YES];
}

#pragma mark - Landing Protocol

- (void)welcomeLandingHaveAccount:(InfinitWelcomeLandingViewController*)sender
{
  // XXX popup old login view.
}

- (void)welcomeLandingNoAccount:(InfinitWelcomeLandingViewController*)sender
{
  [self showViewController:self.email_controller animated:YES reverse:NO];
}

#pragma mark - Email Protocol

- (void)welcomeEmailBack:(InfinitWelcomeEmailViewController*)sender
{
  [self showViewController:self.landing_controller animated:YES reverse:YES];
}

- (void)welcomeEmailNext:(InfinitWelcomeEmailViewController*)sender
               withEmail:(NSString*)email
{

}

- (void)welcomeEmailFacebook:(InfinitWelcomeEmailViewController*)sender
{
  
}

#pragma mark - Keyboard

- (void)hideKeyboardWithAnimation:(BOOL)animate
{
  [self.view endEditing:YES];
  [UIView animateWithDuration:animate ? 0.5f : 0.0f
                   animations:^
  {
    self.view.transform = CGAffineTransformIdentity;
  }];
}

- (void)keyboardWillShow:(NSNotification*)notification
{
  CGSize keyboard_size =
    [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;

  CGFloat delta = -keyboard_size.height;
  if ([InfinitHostDevice smallScreen])
    delta += 70.0f;

  CGAffineTransform transform = CGAffineTransformMakeTranslation(0.0f, delta);

  [UIView animateWithDuration:0.5f
                   animations:^
   {
     self.view.transform = transform;
   }];
}

- (void)keyboardWillHide:(NSNotification*)notification
{
  [UIView animateWithDuration:0.5f
                   animations:^
   {
     self.view.transform = CGAffineTransformIdentity;
   }];
}

#pragma mark - View Helpers

- (NSArray*)constraintsForView:(UIView*)view
{
  NSDictionary* views = @{@"view": view};
  NSMutableArray* res =
    [NSMutableArray arrayWithArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[view]|"
                                                                           options:0
                                                                           metrics:nil 
                                                                             views:views]];
  [res addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[view]|"
                                                                   options:0 
                                                                   metrics:nil 
                                                                     views:views]];
  return res;
}

- (void)showViewController:(UIViewController*)view_controller
                  animated:(BOOL)animate
                   reverse:(BOOL)reverse
{
  if (self.current_controller == view_controller)
    return;
  [view_controller willMoveToParentViewController:self];
  [self addChildViewController:view_controller];
  CGFloat height = self.content_view.bounds.size.height;
  if (animate)
  {
    view_controller.view.alpha = 0.0f;
    view_controller.view.transform = reverse ? CGAffineTransformMakeTranslation(0.0f, -height)
                                             : CGAffineTransformMakeTranslation(0.0f, height);
  }
  if (self.current_controller)
  {
    [self.current_controller willMoveToParentViewController:nil];
  }
  [self.content_view addSubview:view_controller.view];
  [self.view addConstraints:[self constraintsForView:view_controller.view]];
  [view_controller didMoveToParentViewController:self];
  if (animate)
  {
    [UIView animateWithDuration:0.3f
                          delay:reverse ? 0.2f : 0.0f
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^
    {
      view_controller.view.alpha = 1.0f;
      if (self.current_controller)
        self.current_controller.view.alpha = 0.0f;
    } completion:NULL];
    [UIView animateWithDuration:0.5f
                     animations:^
     {
       view_controller.view.transform = CGAffineTransformIdentity;
       if (self.current_controller)
       {
         self.current_controller.view.transform =
          reverse ? CGAffineTransformMakeTranslation(0.0f, height)
                  : CGAffineTransformMakeTranslation(0.0f, -height);
       }
     } completion:^(BOOL finished)
     {
       if (self.current_controller)
       {
         [self.current_controller.view removeFromSuperview];
         [self.current_controller removeFromParentViewController];
         self.current_controller.view.transform = CGAffineTransformIdentity;
         self.current_controller.view.alpha = 1.0f;
       }
       _current_controller = view_controller;
     }];
  }
  else
  {
    _current_controller = view_controller;
  }
}

#pragma mark - Lazy Loading

- (InfinitWelcomeCodeViewController*)code_controller
{
  if (_code_controller == nil)
  {
    NSString* class_name = NSStringFromClass(InfinitWelcomeCodeViewController.class);
    _code_controller = [[InfinitWelcomeCodeViewController alloc] initWithNibName:class_name
                                                                          bundle:nil];
    _code_controller.delegate = self;
  }
  return _code_controller;
}

- (InfinitWelcomeEmailViewController*)email_controller
{
  if (_email_controller == nil)
  {
    NSString* class_name = NSStringFromClass(InfinitWelcomeEmailViewController.class);
    _email_controller = [[InfinitWelcomeEmailViewController alloc] initWithNibName:class_name
                                                                            bundle:nil];
    _email_controller.delegate = self;
  }
  return _email_controller;
}

- (InfinitWelcomeInvitedViewController*)invited_controller
{
  if (_invited_controller == nil)
  {
    NSString* class_name = NSStringFromClass(InfinitWelcomeInvitedViewController.class);
    _invited_controller = [[InfinitWelcomeInvitedViewController alloc] initWithNibName:class_name
                                                                                bundle:nil];
    _invited_controller.delegate = self;
  }
  return _invited_controller;
}

- (InfinitWelcomeLandingViewController*)landing_controller
{
  if (_landing_controller == nil)
  {
    NSString* class_name = NSStringFromClass(InfinitWelcomeLandingViewController.class);
    _landing_controller = [[InfinitWelcomeLandingViewController alloc] initWithNibName:class_name
                                                                                bundle:nil];
    _landing_controller.delegate = self;
  }
  return _landing_controller;
}

- (InfinitWelcomeLastStepViewController*)last_step_controller
{
  if (_last_step_controller == nil)
  {
    NSString* class_name = NSStringFromClass(InfinitWelcomeLastStepViewController.class);
    _last_step_controller = [[InfinitWelcomeLastStepViewController alloc] initWithNibName:class_name
                                                                                   bundle:nil];
    _last_step_controller.delegate = self;
  }
  return _last_step_controller;
}

- (InfinitWelcomePasswordViewController*)password_controller
{
  if (_password_controller == nil)
  {
    NSString* class_name = NSStringFromClass(InfinitWelcomePasswordViewController.class);
    _password_controller = [[InfinitWelcomePasswordViewController alloc] initWithNibName:class_name
                                                                                  bundle:nil];
    _password_controller.delegate = self;
  }
  return _password_controller;
}

- (UIMotionEffectGroup*)balloonParallax
{
  UIInterpolatingMotionEffect* v_effect =
    [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.y"
                                                    type:UIInterpolatingMotionEffectTypeTiltAlongVerticalAxis];
  v_effect.minimumRelativeValue = @(-25.0f);
  v_effect.maximumRelativeValue = @(25.0f);

  UIInterpolatingMotionEffect* h_effect =
  [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.x"
                                                  type:UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis];
  h_effect.minimumRelativeValue = @(-25.0f);
  h_effect.maximumRelativeValue = @(25.0f);

  UIMotionEffectGroup* group = [UIMotionEffectGroup new];
  group.motionEffects = @[h_effect, v_effect];
  return group;
}

@end
