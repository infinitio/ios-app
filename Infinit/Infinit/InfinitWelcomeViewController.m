//
//  InfinitWelcomeViewController.m
//  Infinit
//
//  Created by Christopher Crone on 23/04/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitWelcomeViewController.h"

#import "InfinitApplicationSettings.h"
#import "InfinitBackgroundManager.h"
#import "InfinitColor.h"
#import "InfinitConstants.h"
#import "InfinitDownloadFolderManager.h"
#import "InfinitFacebookManager.h"
#import "InfinitGalleryManager.h"
#import "InfinitHostDevice.h"
#import "InfinitRatingManager.h"
#import "InfinitWelcomeAvatarViewController.h"
#import "InfinitWelcomeCodeViewController.h"
#import "InfinitWelcomeEmailViewController.h"
#import "InfinitWelcomeFacebookUser.h"
#import "InfinitWelcomeInvitedViewController.h"
#import "InfinitWelcomeLandingViewController.h"
#import "InfinitWelcomeLastStepViewController.h"
#import "InfinitWelcomeLoginViewController.h"
#import "InfinitWelcomePasswordViewController.h"

#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>

#import <Gap/InfinitAvatarManager.h>
#import <Gap/InfinitDeviceManager.h>
#import <Gap/InfinitGhostCodeManager.h>
#import <Gap/InfinitKeychain.h>
#import <Gap/InfinitStateManager.h>
#import <Gap/NSString+email.h>

@interface InfinitWelcomeViewController () <InfinitWelcomeAvatarProtocol,
                                            InfinitWelcomeCodeProtocol,
                                            InfinitWelcomeEmailProtocol,
                                            InfinitWelcomeInvitedProtocol,
                                            InfinitWelcomeLandingProtocol,
                                            InfinitWelcomeLastStepProtocol,
                                            InfinitWelcomeLoginProtocol,
                                            InfinitWelcomePasswordProtocol>

@property (nonatomic, weak) IBOutlet UIImageView* balloon_view;
@property (nonatomic, weak) IBOutlet UIView* content_view;
@property (nonatomic, weak) IBOutlet UIImageView* logo_view;

@property (nonatomic, weak) IBOutlet NSLayoutConstraint* top_logo_constraint;

@property (nonatomic, strong) InfinitWelcomeAvatarViewController* avatar_controller;
@property (nonatomic, strong) InfinitWelcomeCodeViewController* code_controller;
@property (nonatomic, strong) InfinitWelcomeEmailViewController* email_controller;
@property (nonatomic, strong) InfinitWelcomeInvitedViewController* invited_controller;
@property (nonatomic, strong) InfinitWelcomeLandingViewController* landing_controller;
@property (nonatomic, strong) InfinitWelcomeLastStepViewController* last_step_controller;
@property (nonatomic, strong) InfinitWelcomeLoginViewController* login_controller;
@property (nonatomic, strong) InfinitWelcomePasswordViewController* password_controller;

@property (nonatomic, weak) InfinitWelcomeAbstractViewController* current_controller;

@property (nonatomic, readonly) UIImage* avatar;
@property (nonatomic, readonly) NSString* email;
@property (nonatomic, readonly) InfinitWelcomeFacebookUser* facebook_user;
@property (nonatomic, readonly) NSString* name;
@property (nonatomic, readonly) NSString* password;

@end

static dispatch_once_t _avatar_token = 0;
static dispatch_once_t _code_token = 0;
static dispatch_once_t _email_token = 0;
static dispatch_once_t _invited_token = 0;
static dispatch_once_t _landing_token = 0;
static dispatch_once_t _last_step_token = 0;
static dispatch_once_t _login_token = 0;
static dispatch_once_t _password_token = 0;

@implementation InfinitWelcomeViewController

- (void)dealloc
{
  _avatar_token = 0;
  _code_token = 0;
  _email_token = 0;
  _invited_token = 0;
  _landing_token = 0;
  _last_step_token = 0;
  _login_token = 0;
  _password_token = 0;
}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
  if (self.current_controller != _avatar_controller)
  {
    _avatar_token = 0;
    _avatar_controller = nil;
  }
  if (self.current_controller != _code_controller)
  {
    _code_token = 0;
    _code_controller = nil;
  }
  if (self.current_controller != _email_controller)
  {
    _email_token = 0;
    _email_controller = nil;
  }
  if (self.current_controller != _invited_controller)
  {
    _invited_token = 0;
    _invited_controller = nil;
  }
  if (self.current_controller != _landing_controller)
  {
    _landing_token = 0;
    _landing_controller = nil;
  }
  if (self.current_controller != _last_step_controller)
  {
    _last_step_token = 0;
    _last_step_controller = nil;
  }
  if (self.current_controller != _login_controller)
  {
    _login_token = 0;
    _login_controller = nil;
  }
  if (self.current_controller != _password_controller)
  {
    _password_token = 0;
    _password_controller = nil;
  }
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
  {
    self.top_logo_constraint.constant = 250.0f;
  }
  _current_controller = nil;
  [self showViewController:self.landing_controller animated:NO reverse:NO];
  [self.balloon_view addMotionEffect:[self balloonParallax]];
  Class this_class = InfinitWelcomeViewController.class;
  UIColor* cursor_color = [InfinitColor colorFromPalette:InfinitPaletteColorLoginBlack];
  [[UITextField appearanceWhenContainedIn:this_class, nil] setTintColor:cursor_color];
  if ([InfinitHostDevice iOSVersion] < 8.0f)
  {
    self.content_view.clipsToBounds = YES;
  }
}

- (void)viewWillAppear:(BOOL)animated
{
  [[InfinitFacebookManager sharedInstance] logout];
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
  if (self.current_controller == nil)
  {
    [self showViewController:self.landing_controller animated:NO reverse:NO];
  }
}

- (void)viewWillDisappear:(BOOL)animated
{
  [super viewWillDisappear:animated];
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)backgroundedApp
{
  [self hideKeyboardWithAnimation:NO];
}

- (IBAction)viewTapped:(id)sender
{
  [self hideKeyboardWithAnimation:YES];
}

- (void)openFacebookSession
{
  if ([FBSDKAccessToken currentAccessToken])
  {
    [self fetchFacebookMeData];
    return;
  }
  InfinitFacebookManager* manager = [InfinitFacebookManager sharedInstance];
  __weak InfinitWelcomeViewController* weak_self = self;
  [manager.login_manager logInWithReadPermissions:kInfinitFacebookReadPermissions
                                          handler:^(FBSDKLoginManagerLoginResult* result,
                                                    NSError* error)
  {
    if (!weak_self)
      return;
    InfinitWelcomeViewController* strong_self = weak_self;
    if (!error && !result.isCancelled)
    {
      [strong_self fetchFacebookMeData];
      return;
    }
    dispatch_async(dispatch_get_main_queue(), ^
    {
      InfinitWelcomeViewController* strong_self = weak_self;
      [strong_self.current_controller resetView];
      NSString* title = NSLocalizedString(@"Unable to login with Facebook", nil);
      NSString* message = nil;
      if (error)
        message = error.localizedDescription;
      else if (result.isCancelled)
        message = NSLocalizedString(@"Facebook login cancelled.", nil);
      UIAlertView* alert = [[UIAlertView alloc] initWithTitle:title
                                                      message:message
                                                     delegate:self
                                            cancelButtonTitle:@"OK"
                                            otherButtonTitles:nil];
      [alert show];
    });
  }];
}

- (void)showMainView
{
  [InfinitBackgroundManager sharedInstance];
  [InfinitDeviceManager sharedInstance];
  [InfinitDownloadFolderManager sharedInstance];
  [InfinitGalleryManager sharedInstance];
  [InfinitRatingManager sharedInstance];
  NSString* identifier = nil;
  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    identifier = @"main_controller_ipad";
  else
    identifier = @"main_controller_id";
  self.view.window.rootViewController =
    [self.storyboard instantiateViewControllerWithIdentifier:identifier];
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)),
                 dispatch_get_main_queue(), ^
  {
    [self removeFromParentViewController];
    _avatar = nil;
    _email = nil;
    _facebook_user = nil;
    _name = nil;
    _password = nil;
    _avatar_token = 0;
    _avatar_controller = nil;
    _code_token = 0;
    _code_controller = nil;
    _email_token = 0;
    _email_controller = nil;
    _invited_token = 0;
    _invited_controller = nil;
    _landing_token = 0;
    _landing_controller = nil;
    _last_step_token = 0;
    _last_step_controller = nil;
    _login_token = 0;
    _login_controller = nil;
    _password_token = 0;
    _password_controller = nil;
  });
}

#pragma mark - Abstract Protocol

- (NSString*)errorStringForGapStatus:(gap_Status)status
{
  switch (status)
  {
    case gap_already_logged_in:
      return NSLocalizedString(@"You're already logged in.", nil);
    case gap_deprecated:
      return NSLocalizedString(@"Please update Infinit.", nil);
    case gap_email_already_registered:
      return NSLocalizedString(@"Email already registered.", nil);
    case gap_email_not_confirmed:
      return NSLocalizedString(@"Your email has not been confirmed.", nil);
    case gap_email_not_valid:
      return NSLocalizedString(@"Email not valid.", nil);
    case gap_email_password_dont_match:
      return NSLocalizedString(@"Login/Password don't match.", nil);
    case gap_fullname_not_valid:
      return NSLocalizedString(@"Fullname not valid.", nil);
    case gap_handle_already_registered:
      return NSLocalizedString(@"This handle has already been taken.", nil);
    case gap_handle_not_valid:
      return NSLocalizedString(@"Handle not valid", nil);
    case gap_meta_down_with_message:
      return NSLocalizedString(@"Our Server is down.\nThanks for being patient.", nil);
    case gap_password_not_valid:
      return NSLocalizedString(@"Password not valid.", nil);

    default:
      return [NSString stringWithFormat:@"%@: %d", NSLocalizedString(@"Unknown login error", nil),
              status];
  }
}

#pragma mark - Landing Protocol

- (void)welcomeLandingHaveAccount:(InfinitWelcomeLandingViewController*)sender
{
  [self showViewController:self.login_controller animated:YES reverse:NO];
}

- (void)welcomeLandingNoAccount:(InfinitWelcomeLandingViewController*)sender
{
  [self showViewController:self.email_controller animated:YES reverse:NO];
}

#pragma mark - Login Protocol

- (void)welcomeLoginBack:(InfinitWelcomeLoginViewController*)sender
{
  [self showViewController:self.landing_controller animated:YES reverse:YES];
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(500 * NSEC_PER_MSEC)),
                 dispatch_get_main_queue(), ^
  {
    [self.login_controller resetView];
  });
}

- (void)welcomeLoginDone:(InfinitWelcomeLoginViewController*)sender
{
  [self storeCredentials];
  [self showMainView];
}

- (void)welcomeLogin:(InfinitWelcomeLoginViewController*)sender
               email:(NSString*)email
            password:(NSString*)password
     completionBlock:(InfinitWelcomeResultBlock)completion_block
{
  _email = email;
  _password = password;
  [[InfinitStateManager sharedInstance] login:email
                                     password:password
                              completionBlock:completion_block];
}

- (void)welcomeLoginFacebook:(InfinitWelcomeLoginViewController*)sender
{
  [self openFacebookSession];
}

#pragma mark - Email Protocol

- (void)welcomeEmailBack:(InfinitWelcomeEmailViewController*)sender
{
  if (self.facebook_user)
    _facebook_user = nil;
  [self showViewController:self.landing_controller animated:YES reverse:YES];
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(500 * NSEC_PER_MSEC)),
                 dispatch_get_main_queue(), ^
  {
    [self.email_controller resetView];
  });
}

- (void)welcomeEmailNext:(InfinitWelcomeEmailViewController*)sender
               withEmail:(NSString*)email
         completionBlock:(InfinitWelcomeEmailBlock)completion_block
{
  _email = email;
  if (self.facebook_user)
  {
    self.facebook_user.email = email;
    if (![InfinitGhostCodeManager sharedInstance].code_set)
      [self showViewController:self.invited_controller animated:YES reverse:NO];
  }
  else
  {
    [[InfinitStateManager sharedInstance] accountStatusForEmail:self.email
                                                completionBlock:^(InfinitStateResult* result,
                                                                  NSString* email,
                                                                  AccountStatus status)
    {
      __weak InfinitWelcomeAbstractViewController* view_controller = nil;
      switch (status)
      {
        case gap_account_status_ghost:
          view_controller = self.last_step_controller;
          break;
        case gap_account_status_registered:
          view_controller = self.password_controller;
          break;

        case gap_account_status_new:
        default:
          if ([InfinitGhostCodeManager sharedInstance].code_set)
            view_controller = self.last_step_controller;
          else
            view_controller = self.invited_controller;
          break;
      }
      [self.email_controller gotEmailAccountType];
      [self showViewController:view_controller animated:YES reverse:NO];
      completion_block();
    }];
  }
}

- (void)welcomeEmailFacebook:(InfinitWelcomeEmailViewController*)sender
{
  [self openFacebookSession];
}

#pragma mark - Invitation Protocol

- (void)welcomeInvited:(InfinitWelcomeInvitedViewController*)sender
{
  [self showViewController:self.code_controller animated:YES reverse:NO];
}

- (void)welcomeNotInvited:(InfinitWelcomeInvitedViewController*)sender
{
  if (self.facebook_user)
  {
    [self.invited_controller facebookRegister];
    [self facebookConnect];
  }
  else
  {
    [self showViewController:self.last_step_controller animated:YES reverse:NO];
  }
}

#pragma mark - Code Protocol

- (void)welcomeCode:(InfinitWelcomeCodeViewController*)sender
       doneWithCode:(NSString*)code
{
  [[InfinitGhostCodeManager sharedInstance] setCode:code wasLink:NO completionBlock:nil];
  if (self.facebook_user)
  {
    [self.code_controller facebookRegister];
    [self facebookConnect];
  }
  else
  {
    [self showViewController:self.last_step_controller animated:YES reverse:NO];
  }
}

#pragma mark - Last Step Protocol

- (void)welcomeLastStepBack:(InfinitWelcomeLastStepViewController*)sender
{
  [self.landing_controller resetView];
  [self.login_controller resetView];
  [self.email_controller resetView];
  [self.invited_controller resetView];
  [self.code_controller resetView];
  [self showViewController:self.landing_controller animated:YES reverse:YES];
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(500 * NSEC_PER_MSEC)),
                 dispatch_get_main_queue(), ^
  {
    [self.last_step_controller resetView];
  });
}

- (void)welcomeLastStepRegister:(InfinitWelcomeLastStepViewController*)sender
                           name:(NSString*)name
                       password:(NSString*)password
                completionBlock:(InfinitWelcomeResultBlock)completion_block
{
  _name = name;
  _password = password;
  [[InfinitStateManager sharedInstance] registerFullname:self.name
                                                   email:self.email
                                                password:self.password
                                         completionBlock:completion_block];
}

- (void)welcomeLastStepFacebookConnect:(InfinitWelcomeLastStepViewController*)sender
{
  [self openFacebookSession];
}

- (void)welcomeLastStepDone:(InfinitWelcomeLastStepViewController*)sender
{
  [self storeCredentials];
  if (self.avatar)
  {
    [[InfinitAvatarManager sharedInstance] setSelfAvatar:self.avatar];
    [self showMainView];
    return;
  }
  [self showViewController:self.avatar_controller animated:YES reverse:NO];
}

#pragma mark - Avatar Protocol

- (void)welcomeAvatarDone:(InfinitWelcomeAvatarViewController*)sender
               withAvatar:(UIImage*)avatar
{
  _avatar = avatar;
  if (self.avatar)
    [[InfinitAvatarManager sharedInstance] setSelfAvatar:self.avatar];

  [self showMainView];
}

#pragma mark - Password Protocol

- (void)welcomePasswordBack:(InfinitWelcomePasswordViewController*)sender
{
  [self.email_controller resetView];
  [self showViewController:self.email_controller animated:YES reverse:YES];
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(500 * NSEC_PER_MSEC)),
                 dispatch_get_main_queue(), ^
  {
    [self.password_controller resetView];
  });
}

- (void)welcomePasswordDone:(InfinitWelcomePasswordViewController*)sender
{
  [self storeCredentials];
  [self showMainView];
}

- (void)welcomePasswordLogin:(InfinitWelcomePasswordViewController*)sender
                    password:(NSString*)password
             completionBlock:(InfinitWelcomeResultBlock)completion_block
{
  _password = password;
  [[InfinitStateManager sharedInstance] login:self.email
                                     password:password
                              completionBlock:completion_block];
}

- (void)welcomePasswordFacebook:(InfinitWelcomePasswordViewController*)sender
{
  [self openFacebookSession];
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

  [UIView animateWithDuration:0.5f
                   animations:^
   {
     self.view.transform = CGAffineTransformMakeTranslation(0.0f, -keyboard_size.height);
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

- (void)showViewController:(InfinitWelcomeAbstractViewController*)view_controller
                  animated:(BOOL)animate
                   reverse:(BOOL)reverse
{
  if (self.current_controller == view_controller)
    return;
  if (view_controller == self.landing_controller)
  {
    _avatar = nil;
    _email = nil;
    _facebook_user = nil;
    _name = nil;
    _password = nil;
    [[InfinitFacebookManager sharedInstance] logout];
  }
  if ([InfinitHostDevice smallScreen])
  {
    BOOL hide = (view_controller == self.last_step_controller || 
                 view_controller == self.code_controller ||
                 view_controller == self.avatar_controller);
    CGFloat alpha = hide ? 0.0f : 1.0f;
    if (self.logo_view.alpha != alpha)
    {
      if (animate)
      {
        [UIView animateWithDuration:0.3f animations:^
        {
          self.logo_view.alpha = alpha;
        }];
      }
      else
      {
        self.logo_view.alpha = alpha;
      }
    }
  }
  void (^completion_block)(void) = ^()
  {
    if (self.current_controller)
    {
      [self.current_controller.view removeFromSuperview];
      [self.current_controller removeFromParentViewController];
      self.current_controller.view.transform = CGAffineTransformIdentity;
      self.current_controller.view.alpha = 1.0f;
    }
    _current_controller = view_controller;
  };
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
       completion_block();
     }];
  }
  else
  {
    completion_block();
  }
}

#pragma mark - Lazy Loading

- (InfinitWelcomeAvatarViewController*)avatar_controller
{
  dispatch_once(&_avatar_token, ^
  {
    NSString* class_name = NSStringFromClass(InfinitWelcomeAvatarViewController.class);
    _avatar_controller = [[InfinitWelcomeAvatarViewController alloc] initWithNibName:class_name
                                                                              bundle:nil];
    _avatar_controller.delegate = self;
  });
  return _avatar_controller;
}

- (InfinitWelcomeCodeViewController*)code_controller
{
  dispatch_once(&_code_token, ^
  {
    NSString* class_name = NSStringFromClass(InfinitWelcomeCodeViewController.class);
    _code_controller = [[InfinitWelcomeCodeViewController alloc] initWithNibName:class_name
                                                                          bundle:nil];
    _code_controller.delegate = self;
  });
  return _code_controller;
}

- (InfinitWelcomeEmailViewController*)email_controller
{
  dispatch_once(&_email_token, ^
  {
    NSString* class_name = NSStringFromClass(InfinitWelcomeEmailViewController.class);
    _email_controller = [[InfinitWelcomeEmailViewController alloc] initWithNibName:class_name
                                                                            bundle:nil];
    _email_controller.delegate = self;
  });
  return _email_controller;
}

- (InfinitWelcomeInvitedViewController*)invited_controller
{
  dispatch_once(&_invited_token, ^
  {
    NSString* class_name = NSStringFromClass(InfinitWelcomeInvitedViewController.class);
    _invited_controller = [[InfinitWelcomeInvitedViewController alloc] initWithNibName:class_name
                                                                                bundle:nil];
    _invited_controller.delegate = self;
  });
  return _invited_controller;
}

- (InfinitWelcomeLandingViewController*)landing_controller
{
  dispatch_once(&_landing_token, ^
  {
    NSString* class_name = NSStringFromClass(InfinitWelcomeLandingViewController.class);
    _landing_controller = [[InfinitWelcomeLandingViewController alloc] initWithNibName:class_name
                                                                                bundle:nil];
    _landing_controller.delegate = self;
  });
  return _landing_controller;
}

- (InfinitWelcomeLastStepViewController*)last_step_controller
{
  dispatch_once(&_last_step_token, ^
  {
    NSString* class_name = NSStringFromClass(InfinitWelcomeLastStepViewController.class);
    _last_step_controller = [[InfinitWelcomeLastStepViewController alloc] initWithNibName:class_name
                                                                                   bundle:nil];
    _last_step_controller.delegate = self;
  });
  return _last_step_controller;
}

- (InfinitWelcomeLoginViewController*)login_controller
{
  dispatch_once(&_login_token, ^
  {
    NSString* class_name = NSStringFromClass(InfinitWelcomeLoginViewController.class);
    _login_controller = [[InfinitWelcomeLoginViewController alloc] initWithNibName:class_name
                                                                            bundle:nil];
    _login_controller.delegate = self;
  });
  return _login_controller;
}

- (InfinitWelcomePasswordViewController*)password_controller
{
  dispatch_once(&_password_token, ^
  {
    NSString* class_name = NSStringFromClass(InfinitWelcomePasswordViewController.class);
    _password_controller = [[InfinitWelcomePasswordViewController alloc] initWithNibName:class_name
                                                                                  bundle:nil];
    _password_controller.delegate = self;
  });
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
    [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"ceXnter.x"
                                                    type:UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis];
  h_effect.minimumRelativeValue = @(-25.0f);
  h_effect.maximumRelativeValue = @(25.0f);

  UIMotionEffectGroup* group = [UIMotionEffectGroup new];
  group.motionEffects = @[h_effect, v_effect];
  return group;
}

- (UIStoryboard*)storyboard
{
  return [UIStoryboard storyboardWithName:@"Main" bundle:nil];
}

- (void)storeCredentials
{
  if (!self.email.length || !self.password.length)
    return;
  [InfinitApplicationSettings sharedInstance].username = self.email;
  InfinitKeychain* keychain = [InfinitKeychain sharedInstance];
  if ([keychain credentialsForAccountInKeychain:self.email])
    [keychain updatePassword:self.password forAccount:self.email];
  else
    [keychain addPassword:self.password forAccount:self.email];
}

- (void)facebookConnect
{
  NSString* token = [FBSDKAccessToken currentAccessToken].tokenString;
  __weak InfinitWelcomeViewController* weak_self = self;
  [[InfinitStateManager sharedInstance] facebookConnect:token
                                           emailAddress:self.email
                                        completionBlock:^(InfinitStateResult* result)
  {
    InfinitWelcomeViewController* strong_self = weak_self;
    if (result.success)
    {
      if (strong_self.facebook_user.account_status == gap_account_status_ghost ||
          strong_self.facebook_user.account_status == gap_account_status_new ||
          strong_self.facebook_user.account_status == gap_account_status_contact)
      {
        if (strong_self.avatar)
          [[InfinitAvatarManager sharedInstance] setSelfAvatar:strong_self.avatar];
        [strong_self showMainView];
      }
      else
      {
        [strong_self showMainView];
      }
      [InfinitApplicationSettings sharedInstance].login_method = InfinitLoginFacebook;
    }
    else
    {
      [[InfinitFacebookManager sharedInstance] logout];
      [strong_self.current_controller resetView];
    }
  }];
}

- (void)determineFacebookUserType
{
  __weak InfinitWelcomeViewController* weak_self = self;
  [[InfinitStateManager sharedInstance] userRegisteredWithFacebookId:self.facebook_user.id_
                                                     completionBlock:^(InfinitStateResult* result,
                                                                       BOOL registered)
  {
    InfinitWelcomeViewController* strong_self = weak_self;
    if (result.success && registered)
    {
      [strong_self facebookConnect];
    }
    else
    {
      if (strong_self.current_controller == strong_self.email_controller &&
          strong_self.email_controller.email.infinit_isEmail)
      {
        strong_self.facebook_user.email = strong_self.email_controller.email;
        strong_self->_email = strong_self.email_controller.email;
      }
      if (strong_self.current_controller == strong_self.last_step_controller)
        strong_self.facebook_user.email = strong_self.email;
      if (!strong_self.facebook_user.email.length)
      {
        [strong_self showViewController:self.email_controller animated:YES reverse:NO];
        [strong_self.email_controller facebookNoAccount];
        return;
      }
      [[InfinitStateManager sharedInstance] accountStatusForEmail:strong_self.facebook_user.email
                                                  completionBlock:^(InfinitStateResult* result,
                                                                    NSString* email,
                                                                    AccountStatus status)
      {
        InfinitWelcomeViewController* strong_self = weak_self;
        strong_self.facebook_user.account_status = status;
        if (status == gap_account_status_new || status == gap_account_status_contact)
        {
          _name = strong_self.facebook_user.name;
          if (strong_self.current_controller == strong_self.last_step_controller)
          {
            strong_self.last_step_controller.name = strong_self.facebook_user.name;
            [strong_self facebookConnect];
          }
          else if (strong_self.current_controller == strong_self.login_controller)
          {
            [strong_self showViewController:strong_self.email_controller animated:YES reverse:NO];
            strong_self.email_controller.email = strong_self.facebook_user.email;
            [strong_self.email_controller facebookNoAccount];
          }
          else
          {
            if (strong_self.current_controller != strong_self.email_controller)
              [strong_self showViewController:strong_self.email_controller animated:YES reverse:NO];
            else
              [strong_self.email_controller gotEmailAccountType];
            self.email_controller.email = strong_self.facebook_user.email;
          }
        }
        else if (status == gap_account_status_ghost)
        {
          [strong_self showViewController:strong_self.code_controller animated:YES reverse:NO];
        }
        else if (status == gap_account_status_registered)
        {
          // Their Facebook email is already registered so they must do a normal login.
          _email = strong_self.facebook_user.email;
          _facebook_user = nil;
          if (strong_self.current_controller != strong_self.password_controller)
            [strong_self showViewController:strong_self.password_controller animated:YES reverse:NO];
          strong_self.password_controller.hide_facebook_button = YES;
        }
      }];
    }
  }];
}

- (void)fetchFacebookMeData
{
  __weak InfinitWelcomeViewController* weak_self = self;
  FBSDKGraphRequest* me_request =
    [[FBSDKGraphRequest alloc] initWithGraphPath:@"me" parameters:@{@"fields": @"id,name,email"}];
  [me_request startWithCompletionHandler:^(FBSDKGraphRequestConnection* connection,
                                           id result,
                                           NSError* error)
  {
    if (!weak_self)
      return;
    if (error)
    {
      dispatch_async(dispatch_get_main_queue(), ^
      {
        InfinitWelcomeViewController* strong_self = weak_self;
        [strong_self.current_controller resetView];
        NSString* title = NSLocalizedString(@"Unable to fetch Facebook information", nil);
        NSString* message = nil;
        if (error)
          message = error.localizedDescription;
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:title
                                                        message:message
                                                       delegate:self
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
        [strong_self.current_controller resetView];
      });
      return;
    }
    InfinitWelcomeViewController* strong_self = weak_self;
    if ([result isKindOfClass:NSDictionary.class])
    {
      NSDictionary* user_dict = (NSDictionary*)result;
      strong_self->_facebook_user =
        [InfinitWelcomeFacebookUser facebookUserFromGraphDictionary:user_dict];
      dispatch_async(dispatch_get_main_queue(), ^
      {
        InfinitWelcomeViewController* strong_self = weak_self;
        [strong_self determineFacebookUserType];
      });
    }
  }];
}

@end
