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
#import "InfinitDownloadFolderManager.h"
#import "InfinitFacebookManager.h"
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

#import <Gap/InfinitAvatarManager.h>
#import <Gap/InfinitDeviceManager.h>
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
@property (nonatomic, readonly) NSString* code;
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
}

- (void)viewWillAppear:(BOOL)animated
{
  [[InfinitFacebookManager sharedInstance] cleanSession];
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

- (void)fetchFacebookInformation
{
  [[NSNotificationCenter defaultCenter] removeObserver:self
                                                  name:INFINIT_FACEBOOK_SESSION_STATE_CHANGED
                                                object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(facebookSessionStateChanged:)
                                               name:INFINIT_FACEBOOK_SESSION_STATE_CHANGED
                                             object:nil];
  _facebook_user = nil;
  InfinitFacebookManager* manager = [InfinitFacebookManager sharedInstance];
  [FBSession openActiveSessionWithReadPermissions:manager.permission_list
                                     allowLoginUI:YES
                                completionHandler:^(FBSession* session,
                                                    FBSessionState state,
                                                    NSError* error)
   {
     // Call the app delegate's sessionStateChanged:state:error method to handle session state changes
     [manager sessionStateChanged:session state:state error:error];
   }];
}

- (void)showMainView
{
  [InfinitDeviceManager sharedInstance];
  [InfinitDownloadFolderManager sharedInstance];
  [InfinitBackgroundManager sharedInstance];
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
    _code = nil;
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
  [self fetchFacebookInformation];
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
  [self fetchFacebookInformation];
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
  _code = code;
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
  [self fetchFacebookInformation];
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
  if (self.code)
  {
    [[InfinitStateManager sharedInstance] useGhostCode:self.code
                                       completionBlock:^(InfinitStateResult* result)
    {
      [self showViewController:self.avatar_controller animated:YES reverse:NO];
    }];
  }
  else
  {
    [self showViewController:self.avatar_controller animated:YES reverse:NO];
  }
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
  [self fetchFacebookInformation];
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
    _code = nil;
    _email = nil;
    _facebook_user = nil;
    _name = nil;
    _password = nil;
    [[InfinitFacebookManager sharedInstance] cleanSession];
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
  NSString* token = FBSession.activeSession.accessTokenData.accessToken;
  [[InfinitStateManager sharedInstance] facebookConnect:token
                                           emailAddress:self.email 
                                        completionBlock:^(InfinitStateResult* result)
  {
    if (result.success)
    {
      if (self.facebook_user.account_status == gap_account_status_ghost ||
          self.facebook_user.account_status == gap_account_status_new ||
          self.facebook_user.account_status == gap_account_status_contact)
      {
        if (self.avatar)
          [[InfinitAvatarManager sharedInstance] setSelfAvatar:self.avatar];
        if (self.code)
        {
          [[InfinitStateManager sharedInstance] useGhostCode:self.code
                                             completionBlock:^(InfinitStateResult* result)
          {
            [self showMainView];
          }];
        }
        else
        {
          [self showMainView];
        }
      }
      else
      {
        [self showMainView];
      }
    }
    else
    {
      [[InfinitFacebookManager sharedInstance] cleanSession];
      [self.current_controller resetView];
    }
  }];
}

- (void)determineFacebookUserType
{
  [[InfinitStateManager sharedInstance] userRegisteredWithFacebookId:self.facebook_user.id_
                                                     completionBlock:^(InfinitStateResult* result,
                                                                       BOOL registered)
  {
    if (result.success && registered)
    {
      [self facebookConnect];
    }
    else
    {
      if (self.current_controller == self.email_controller &&
          self.email_controller.email.infinit_isEmail)
      {
        self.facebook_user.email = self.email_controller.email;
      }
      [[InfinitStateManager sharedInstance] accountStatusForEmail:self.facebook_user.email
                                                  completionBlock:^(InfinitStateResult* result,
                                                                    NSString* email,
                                                                    AccountStatus status)
      {
        self.facebook_user.account_status = status;
        if (status == gap_account_status_new || status == gap_account_status_contact)
        {
          _name = self.facebook_user.name;
          if (self.current_controller == self.last_step_controller)
          {
            [self facebookConnect];
          }
          else if (self.current_controller == self.login_controller)
          {
            [self showViewController:self.email_controller animated:YES reverse:NO];
            self.email_controller.email = self.facebook_user.email;
            [self.email_controller facebookNoAccount];
          }
          else
          {
            if (self.current_controller != self.email_controller)
              [self showViewController:self.email_controller animated:YES reverse:NO];
            else
              [self.email_controller gotEmailAccountType];
            self.email_controller.email = self.facebook_user.email;
          }
        }
        else if (status == gap_account_status_ghost)
        {
          [self showViewController:self.code_controller animated:YES reverse:NO];
        }
        else if (status == gap_account_status_registered)
        {
          // Their Facebook email is already registered so they must do a normal login.
          _email = self.facebook_user.email;
          _facebook_user = nil;
          self.password_controller.hide_facebook_button = YES;
          if (self.current_controller != self.password_controller)
            [self showViewController:self.password_controller animated:YES reverse:NO];
        }
      }];
    }
  }];
}

- (void)facebookSessionStateChanged:(NSNotification*)notification
{
  [[NSNotificationCenter defaultCenter] removeObserver:self
                                                  name:INFINIT_FACEBOOK_SESSION_STATE_CHANGED
                                                object:nil];
  FBSessionState state = [notification.userInfo[@"state"] unsignedIntegerValue];
  NSError* error = notification.userInfo[@"error"];
  if (state == FBSessionStateOpen || state == FBSessionStateOpenTokenExtended)
  {
    [[FBRequest requestForMe] startWithCompletionHandler:^(FBRequestConnection* connection,
                                                           NSDictionary<FBGraphUser>* fb_user,
                                                           NSError* error)
     {
       if (error)
       {
         [self.current_controller resetView];
       }
       else
       {
         NSData* avatar_data =
           [NSData dataWithContentsOfURL:[self avatarURLForUserWithId:fb_user.objectID]];
         UIImage* avatar = [UIImage imageWithData:avatar_data];
         NSString* email = fb_user[@"email"];
         NSString* name = fb_user.name;
         _avatar = avatar;
         _facebook_user = [InfinitWelcomeFacebookUser facebookUser:fb_user.objectID
                                                             email:email
                                                              name:name
                                                            avatar:avatar];
         dispatch_async(dispatch_get_main_queue(), ^
         {
           [self determineFacebookUserType];
         });
       }
     }];
  }
  else if (state == FBSessionStateClosedLoginFailed || error)
  {
    [self.current_controller resetView];
    NSString* title = NSLocalizedString(@"Unable to login with Facebook", nil);
    NSString* message = nil;
    if (error)
      message = error.localizedDescription;
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:title
                                                    message:message
                                                   delegate:self
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
  }
}

- (NSURL*)avatarURLForUserWithId:(NSString*)id_
{
  NSString* str =
    [NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=large", id_];
  return [NSURL URLWithString:str];
}

@end
