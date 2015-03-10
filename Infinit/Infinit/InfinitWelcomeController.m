//
//  InfinitWelcomeController.m
//  Infinit
//
//  Created by Michael Dee on 12/14/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import "InfinitWelcomeController.h"

#import "AppDelegate.h"

#import "InfinitApplicationSettings.h"
#import "InfinitBackgroundManager.h"
#import "InfinitColor.h"
#import "InfinitDownloadFolderManager.h"
#import "InfinitFacebookManager.h"
#import "InfinitHostDevice.h"
#import "InfinitKeychain.h"
#import "InfinitLoginInvitationCodeController.h"
#import "InfinitRatingManager.h"
#import "WelcomeLoginFormView.h"
#import "WelcomeSignupFacebookView.h"
#import "WelcomeSignupFormView.h"

#import "NSString+email.h"

#import <Gap/InfinitConnectionManager.h>
#import <Gap/InfinitDeviceManager.h>
#import <Gap/InfinitPeerTransactionManager.h>
#import <Gap/InfinitStateManager.h>
#import <Gap/InfinitStateResult.h>
#import <Gap/InfinitUserManager.h>

#import <FacebookSDK/FacebookSDK.h>

#define INFINIT_FORGOT_PASSWORD_URL @"https://infinit.io/forgot_password?utm_source=app&utm_medium=ios&utm_campaign=forgot_password"
#define INFINIT_LEGAL_URL           @"https://infinit.io/legal?utm_source=app&utm_medium=ios&utm_campaign=terms"

@import MobileCoreServices;

@interface InfinitFacebookUser : NSObject

@property (nonatomic, readonly) UIImage* avatar;
@property (nonatomic, readonly) NSString* email;
@property (nonatomic, readonly) NSString* fullname;

+ (instancetype)userWithAvatar:(UIImage*)avatar
                         email:(NSString*)email
                      fullname:(NSString*)fullname;

@end

@implementation InfinitFacebookUser

- (id)initWithAvatar:(UIImage*)avatar
               email:(NSString*)email
            fullname:(NSString*)fullname
{
  if (self = [super init])
  {
    _avatar = avatar;
    _email = email;
    _fullname = fullname;
  }
  return self;
}

+ (instancetype)userWithAvatar:(UIImage*)avatar
                         email:(NSString*)email
                      fullname:(NSString*)fullname
{
  return [[InfinitFacebookUser alloc] initWithAvatar:avatar email:email fullname:fullname];
}

@end

typedef NS_ENUM(NSUInteger, InfinitFacebookConnectType)
{
  InfinitFacebookConnectNone = 0,
  InfinitFacebookConnectRegister,
  InfinitFacebookConnectLogin,
};

@interface InfinitWelcomeController () <UITextFieldDelegate,
                                        UIActionSheetDelegate,
                                        UIImagePickerControllerDelegate,
                                        UINavigationControllerDelegate>

@property (nonatomic, strong) WelcomeLoginFormView* login_form_view;
@property (nonatomic, strong) WelcomeSignupFacebookView* signup_facebook_view;
@property (nonatomic, strong) WelcomeSignupFormView* signup_form_view;

@property (nonatomic, weak) IBOutlet UIImageView* logo_image_view;
@property (nonatomic, weak) IBOutlet UIImageView* balloon_image_view;

@property (nonatomic, weak) IBOutlet UIButton* signup_with_facebook_button;
@property (nonatomic, weak) IBOutlet UIButton* signup_with_email_button;
@property (nonatomic, weak) IBOutlet UIButton* login_button;
@property (nonatomic, weak) IBOutlet UILabel* tagline;

@property (nonatomic, strong) UIImage* avatar_image;
@property (nonatomic, strong) UIImagePickerController* picker;

@property (nonatomic, readonly) InfinitFacebookConnectType facebook_connect_type;
@property (nonatomic, readonly) InfinitFacebookUser* facebook_user;

@end

@implementation InfinitWelcomeController
{
@private
  NSString* _password;
  NSString* _username;

  BOOL _logging_in;
  BOOL _registering;
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL)prefersStatusBarHidden
{
  return YES;
}

- (BOOL)shouldAutorotate
{
  return NO;
}

- (NSUInteger)supportedInterfaceOrientations
{
  return UIInterfaceOrientationMaskPortrait;
}

- (void)viewDidLoad
{
  [super viewDidLoad];

  [self addBalloonParallax];

  CAGradientLayer* gradient = [CAGradientLayer layer];
  gradient.frame = self.view.bounds;
  gradient.startPoint = CGPointMake(0.0f, 0.0f);
  gradient.endPoint = CGPointMake(0.0f, 0.7f);
  gradient.colors = @[(id)[InfinitColor colorWithRed:226 green:228 blue:227].CGColor,
                      (id)[InfinitColor colorWithRed:227 green:231 blue:233].CGColor,
                      (id)[InfinitColor colorWithRed:230 green:235 blue:238].CGColor,
                      (id)[InfinitColor colorWithRed:234 green:240 blue:243].CGColor,
                      (id)[InfinitColor colorWithRed:239 green:244 blue:248].CGColor,
                      (id)[InfinitColor colorWithRed:240 green:250 blue:251].CGColor,
                      (id)[InfinitColor colorWithRed:244 green:252 blue:252].CGColor,
                      (id)[InfinitColor colorWithRed:246 green:252 blue:252].CGColor,
                      (id)[InfinitColor colorWithRed:255 green:255 blue:255].CGColor];
  [self.view.layer insertSublayer:gradient atIndex:0];

  self.signup_with_facebook_button.layer.cornerRadius =
    self.signup_with_facebook_button.bounds.size.height / 2.0f;
  self.signup_with_email_button.layer.cornerRadius =
    self.signup_with_email_button.bounds.size.height / 2.0f;
  self.login_button.layer.cornerRadius = self.login_button.bounds.size.height / 2.0f;

  [self configureLoginView];
  [self configureFacebookView];
  [self configureSignupView];
}

- (void)viewWillAppear:(BOOL)animated
{
  [[UIApplication sharedApplication] setStatusBarHidden:YES
                                          withAnimation:UIStatusBarAnimationFade];
  [super viewWillAppear:animated];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(keyboardWillShow:)
                                               name:UIKeyboardWillShowNotification
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(textDidChange:)
                                               name:UITextFieldTextDidChangeNotification
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(connectionTypeChanged:)
                                               name:INFINIT_CONNECTION_TYPE_CHANGE
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(facebookSessionStateChanged:)
                                               name:INFINIT_FACEBOOK_SESSION_STATE_CHANGED
                                             object:nil];
  _facebook_connect_type = InfinitFacebookConnectNone;
}

- (void)viewDidAppear:(BOOL)animated
{
  _logging_in = NO;
  _registering = NO;
  if ([[InfinitApplicationSettings sharedInstance] username] != nil)
  {
    NSString* account = [[InfinitApplicationSettings sharedInstance] username];
    NSString* password = [[InfinitKeychain sharedInstance] passwordForAccount:account];
    self.login_form_view.email_field.text = account;
    self.login_form_view.password_field.text = [password copy];
    self.login_form_view.forgot_button.hidden = (password.length > 0);
    password = nil;
    [self checkLoginInputs];
  }
  [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
  [[UIApplication sharedApplication] setStatusBarHidden:NO
                                          withAnimation:UIStatusBarAnimationFade];
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [super viewWillDisappear:animated];
}

- (void)configureLoginView
{
  UINib* login_nib = [UINib nibWithNibName:@"WelcomeLoginFormView" bundle:nil];
  self.login_form_view = [[login_nib instantiateWithOwner:self options:nil] firstObject];
  self.login_form_view.frame = CGRectMake(0.0f, self.view.frame.size.height,
                                          self.view.frame.size.width, self.view.frame.size.height);
  [self.view addSubview:self.login_form_view];
  [self.view bringSubviewToFront:self.login_form_view];

  self.login_form_view.email_field.delegate = self;
  self.login_form_view.password_field.delegate = self;

  [self.login_form_view.email_field addTarget:self
                                       action:@selector(loginEmailTextChanged:)
                             forControlEvents:UIControlEventEditingChanged];
  [self.login_form_view.email_field addTarget:self
                                       action:@selector(loginEmailTextEditingEnded:)
                             forControlEvents:UIControlEventEditingDidEnd];
  [self.login_form_view.password_field addTarget:self
                                          action:@selector(loginPasswordTextChanged:)
                                forControlEvents:UIControlEventEditingChanged];
  [self.login_form_view.password_field addTarget:self
                                          action:@selector(loginPasswordTextEditingEnded:)
                             forControlEvents:UIControlEventEditingDidEnd];

  [self.login_form_view.back_button addTarget:self
                                       action:@selector(overlayBackButtonTapped:)
                             forControlEvents:UIControlEventTouchUpInside];
  [self.login_form_view.next_button addTarget:self
                                       action:@selector(loginNextButtonTapped:)
                             forControlEvents:UIControlEventTouchUpInside];
  [self.login_form_view.facebook_button addTarget:self
                                           action:@selector(facebookLoginButtonTapped:)
                                 forControlEvents:UIControlEventTouchUpInside];
  [self.login_form_view.forgot_button addTarget:self
                                         action:@selector(forgotPasswordTapped:)
                               forControlEvents:UIControlEventTouchUpInside];
}

- (void)configureFacebookView
{
  UINib* facebook_nib = [UINib nibWithNibName:NSStringFromClass(WelcomeSignupFacebookView.class)
                                       bundle:nil];
  self.signup_facebook_view = [[facebook_nib instantiateWithOwner:self options:nil] firstObject];
  self.signup_facebook_view.frame = CGRectMake(0.0f, self.view.frame.size.height,
                                           self.view.frame.size.width, self.view.frame.size.height);
  [self.view addSubview:self.signup_facebook_view];
  [self.view bringSubviewToFront:self.signup_facebook_view];

  self.signup_facebook_view.email_field.delegate = self;
  self.signup_facebook_view.fullname_field.delegate = self;

  [self.signup_facebook_view.email_field addTarget:self
                                            action:@selector(facebookEmailTextChanged:)
                                  forControlEvents:UIControlEventEditingChanged];
  [self.signup_facebook_view.email_field addTarget:self
                                            action:@selector(facebookEmailTextEditingEnded:)
                                  forControlEvents:UIControlEventEditingDidEnd];
  [self.signup_facebook_view.fullname_field addTarget:self
                                               action:@selector(facebookFullnameTextChanged:)
                                     forControlEvents:UIControlEventEditingChanged];
  [self.signup_facebook_view.fullname_field addTarget:self
                                               action:@selector(facebookFullnameTextEditingEnded:)
                                     forControlEvents:UIControlEventEditingDidEnd];

  [self.signup_facebook_view.back_button addTarget:self
                                            action:@selector(overlayBackButtonTapped:)
                                  forControlEvents:UIControlEventTouchUpInside];
  [self.signup_facebook_view.next_button addTarget:self
                                            action:@selector(facebookNextButtonTapped:)
                                  forControlEvents:UIControlEventTouchUpInside];
  [self.signup_facebook_view.avatar_button addTarget:self
                                              action:@selector(avatarButtonTapped:)
                                    forControlEvents:UIControlEventTouchUpInside];
  [self.signup_facebook_view.legal_button addTarget:self
                                             action:@selector(legalLinkTapped:)
                                   forControlEvents:UIControlEventTouchUpInside];
}

- (void)configureSignupView
{
  UINib* signup_nib = [UINib nibWithNibName:@"WelcomeSignupFormView" bundle:nil];
  self.signup_form_view = [[signup_nib instantiateWithOwner:self options:nil] firstObject];
  self.signup_form_view.frame = CGRectMake(0.0f, self.view.frame.size.height,
                                           self.view.frame.size.width, self.view.frame.size.height);
  [self.view addSubview:self.signup_form_view];
  [self.view bringSubviewToFront:self.signup_form_view];

  self.signup_form_view.email_field.delegate = self;
  self.signup_form_view.fullname_field.delegate = self;
  self.signup_form_view.password_field.delegate = self;

  [self.signup_form_view.email_field addTarget:self
                                        action:@selector(signupEmailTextChanged:)
                              forControlEvents:UIControlEventEditingChanged];
  [self.signup_form_view.email_field addTarget:self
                                        action:@selector(signupEmailTextEditingEnded:)
                              forControlEvents:UIControlEventEditingDidEnd];
  [self.signup_form_view.fullname_field addTarget:self
                                           action:@selector(signupFullnameTextChanged:)
                                 forControlEvents:UIControlEventEditingChanged];
  [self.signup_form_view.fullname_field addTarget:self
                                           action:@selector(signupFullnameTextEditingEnded:)
                                 forControlEvents:UIControlEventEditingDidEnd];
  [self.signup_form_view.password_field addTarget:self
                                           action:@selector(signupPasswordTextChanged:)
                                 forControlEvents:UIControlEventEditingChanged];
  [self.signup_form_view.password_field addTarget:self
                                          action:@selector(signupPasswordTextEditingEnded:)
                                 forControlEvents:UIControlEventEditingDidEnd];

  [self.signup_form_view.back_button addTarget:self
                                        action:@selector(overlayBackButtonTapped:)
                              forControlEvents:UIControlEventTouchUpInside];
  [self.signup_form_view.next_button addTarget:self
                                        action:@selector(registerNextButtonTapped:)
                              forControlEvents:UIControlEventTouchUpInside];
  [self.signup_form_view.avatar_button addTarget:self
                                          action:@selector(avatarButtonTapped:)
                                forControlEvents:UIControlEventTouchUpInside];
  [self.signup_form_view.legal_button addTarget:self 
                                         action:@selector(legalLinkTapped:)
                               forControlEvents:UIControlEventTouchUpInside];
}

- (void)addBalloonParallax
{
  // Set vertical effect
  UIInterpolatingMotionEffect* vertical =
    [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.y"
                                                    type:UIInterpolatingMotionEffectTypeTiltAlongVerticalAxis];
  vertical.minimumRelativeValue = @(-25.0f);
  vertical.maximumRelativeValue = @(25.0f);

  // Set horizontal effect
  UIInterpolatingMotionEffect* horizontal =
    [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.x"
                                                    type:UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis];
  horizontal.minimumRelativeValue = @(-25.0f);
  horizontal.maximumRelativeValue = @(25.0f);

  // Create group to combine both
  UIMotionEffectGroup* group = [UIMotionEffectGroup new];
  group.motionEffects = @[horizontal, vertical];

  // Add both effects to your view
  [self.balloon_image_view addMotionEffect:group];
}

#pragma mark - Button Handling

- (void)facebookLoginButtonTapped:(id)sender
{
  if (![[NSThread currentThread] isEqual:[NSThread mainThread]])
  {
    [self performSelectorOnMainThread:@selector(facebookLoginButtonTapped:)
                           withObject:sender
                        waitUntilDone:NO];
    return;
  }
  _facebook_connect_type = InfinitFacebookConnectLogin;
  if (FBSession.activeSession.state == FBSessionStateOpen &&
      FBSession.activeSession.state == FBSessionStateOpenTokenExtended)
  {
    [self tryFacebookLogin];
  }
  else
  {
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
}

- (IBAction)facebookRegisterButtonTapped:(id)sender
{
  if (![[NSThread currentThread] isEqual:[NSThread mainThread]])
  {
    [self performSelectorOnMainThread:@selector(facebookRegisterButtonTapped:)
                           withObject:sender
                        waitUntilDone:NO];
    return;
  }
  _facebook_connect_type = InfinitFacebookConnectRegister;
  // If the session state is any of the two "open" states when the button is clicked
  if (FBSession.activeSession.state == FBSessionStateOpen
      || FBSession.activeSession.state == FBSessionStateOpenTokenExtended)
  {
    // Close the session and remove the access token from the cache
    // The session state handler (in the app delegate) will be called automatically
    [FBSession.activeSession closeAndClearTokenInformation];
  }

  InfinitFacebookManager* manager = [InfinitFacebookManager sharedInstance];
  // Open a session showing the user the login UI
  // You must ALWAYS ask for public_profile permissions when opening a session
  [FBSession openActiveSessionWithReadPermissions:manager.permission_list
                                     allowLoginUI:YES
                                completionHandler:^(FBSession* session,
                                                    FBSessionState state,
                                                    NSError* error)
   {
     [manager sessionStateChanged:session state:state error:error];
   }];
  [self showOverlayView:self.signup_facebook_view ofHeight:self.signup_facebook_view.height];
  [self.signup_facebook_view.activity startAnimating];
  self.signup_facebook_view.fullname_field.enabled = NO;
  self.signup_facebook_view.email_field.enabled = NO;
}

- (IBAction)loginOrRegisterTapped:(id)sender
{
  UIView* overlay_view = nil;
  CGFloat height = 0.0;
  if (sender == self.signup_with_email_button)
  {
    overlay_view = self.signup_form_view;
    height = self.signup_form_view.height;
  }
  else if (sender == self.login_button)
  {
    overlay_view = self.login_form_view;
    height = self.login_form_view.height;
  }
  if (overlay_view == nil)
    return;
  [self showOverlayView:overlay_view ofHeight:height];
}

- (void)showOverlayView:(UIView*)overlay_view
               ofHeight:(CGFloat)height
{
  [self.view bringSubviewToFront:overlay_view];
  CGRect new_frame = CGRectMake(0.0f, self.view.frame.size.height - height,
                                self.view.frame.size.width, overlay_view.frame.size.height);
  [UIView animateWithDuration:0.5f
                        delay:0.1f
       usingSpringWithDamping:0.7f
        initialSpringVelocity:20.f
                      options:0
                   animations:^
   {
     overlay_view.frame = new_frame;
   } completion:^(BOOL finished)
   {
     if (!finished)
     {
       overlay_view.frame = new_frame;
     }
   }];
}

- (void)overlayBackButtonTapped:(id)sender
{
  UIView* overlay_view = nil;
  if (sender == self.signup_form_view.back_button)
  {
    overlay_view = self.signup_form_view;
  }
  else if (sender == self.signup_facebook_view.back_button)
  {
    overlay_view = self.signup_facebook_view;
    [[InfinitFacebookManager sharedInstance] cleanSession];
  }
  else if (sender == self.login_form_view.back_button)
  {
    overlay_view = self.login_form_view;
  }
  if (overlay_view == nil)
    return;
  CGRect overlay_frame = CGRectMake(0.0f, self.view.frame.size.height,
                                    overlay_view.frame.size.width, overlay_view.frame.size.height);
  if (self.view.frame.origin.y != 0.0f)
  {
    [self.view endEditing:YES];
    CGRect main_frame = CGRectMake(0.0f, 0.0f,
                                   self.view.frame.size.width, self.view.frame.size.height);
    [UIView animateWithDuration:0.25f
                          delay:0.0f
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^
    {
      self.view.frame = main_frame;
    } completion:^(BOOL finished)
    {
      if (finished)
      {
        [UIView animateWithDuration:0.25f
                              delay:0.0f
                            options:UIViewAnimationOptionCurveEaseInOut animations:^
        {
          overlay_view.frame = overlay_frame;
        } completion:^(BOOL finished)
        {
          if (!finished)
          {
            overlay_view.frame = overlay_frame;
          }
        }];
      }
      else
      {
        self.view.frame = main_frame;
        overlay_view.frame = overlay_frame;
      }
    }];
  }
  else
  {
    [UIView animateWithDuration:0.5f
                          delay:0.1f
         usingSpringWithDamping:0.7f
          initialSpringVelocity:20.f
                        options:0
                     animations:^
     {
       overlay_view.frame = overlay_frame;

     } completion:^(BOOL finished)
     {
       if (!finished)
       {
         overlay_view.frame = overlay_frame;
       }
     }];
  }
}

- (void)keyboardEntryDone
{
  CGRect main_frame = CGRectMake(0.0f, 0.0f,
                                 self.view.frame.size.width, self.view.frame.size.height);
  [UIView animateWithDuration:0.5f
                        delay:0.0f
                      options:UIViewAnimationOptionCurveEaseInOut
                   animations:^
  {
    self.view.frame = main_frame;
  } completion:^(BOOL finished)
  {
    if (!finished)
    {
      self.view.frame = main_frame;
    }
  }];
}

- (void)loginNextButtonTapped:(id)sender
{
  self.login_form_view.next_button.enabled = NO;
  [self tryLogin];
}

- (void)facebookNextButtonTapped:(id)sender
{
  self.signup_facebook_view.next_button.enabled = NO;
  [self tryFacebookRegister];
}

- (void)registerNextButtonTapped:(id)sender
{
  self.signup_form_view.next_button.enabled = NO;
  [self tryRegister];
}

#pragma mark - Login Input Checks

- (void)checkLoginInputs
{
  [self loginInputsGood];
}

- (BOOL)loginInputsGood
{
  if (self.login_form_view.email_field.text.isEmail &&
      self.login_form_view.password_field.text.length > 0)
  {
    self.login_form_view.next_button.enabled = YES;
    self.login_form_view.next_button.hidden = NO;
    return YES;
  }
  else
  {
    self.login_form_view.next_button.hidden = YES;
    self.login_form_view.next_button.enabled = NO;
    return NO;
  }
}

- (void)loginEmailTextChanged:(id)sender
{
  if (self.login_form_view.email_field.text.length == 0)
  {
    self.login_form_view.email_image.image = [UIImage imageNamed:@"icon-email"];
  }
  [self checkLoginInputs];
}

- (void)loginEmailTextEditingEnded:(id)sender
{
  NSCharacterSet* white_space = [NSCharacterSet whitespaceCharacterSet];
  self.login_form_view.email_field.text =
    [self.login_form_view.email_field.text stringByTrimmingCharactersInSet:white_space];
  if (self.login_form_view.email_field.text.isEmail)
  {
    self.login_form_view.email_image.image = [UIImage imageNamed:@"icon-email-valid"];
    self.login_form_view.error_label.hidden = YES;
  }
  else
  {
    self.login_form_view.email_image.image = [UIImage imageNamed:@"icon-email-error"];
    self.login_form_view.error_label.text = NSLocalizedString(@"Email not valid.", nil);
    self.login_form_view.error_label.hidden = NO;
  }
}

- (void)loginPasswordTextChanged:(id)sender
{
  if (self.login_form_view.password_field.text.length == 0)
  {
    self.login_form_view.password_image.image = [UIImage imageNamed:@"icon-password"];
  }
  self.login_form_view.error_label.hidden = YES;
  [self checkLoginInputs];
}

- (void)loginPasswordTextEditingEnded:(id)sender
{
  if (self.login_form_view.password_field.text.length == 0)
  {
    self.login_form_view.password_image.image = [UIImage imageNamed:@"icon-password-error"];
    self.login_form_view.error_label.text = NSLocalizedString(@"Enter a password.", nil);
    self.login_form_view.error_label.hidden = NO;
  }
  else
  {
    self.login_form_view.password_image.image = [UIImage imageNamed:@"icon-password-valid"];
  }
}

- (void)forgotPasswordTapped:(id)sender
{
  NSURL* url = [NSURL URLWithString:INFINIT_FORGOT_PASSWORD_URL];
  [[UIApplication sharedApplication] openURL:url];
}

#pragma mark - Register Input Checks

- (void)checkFacebookInputs
{
  [self facebookInputsGood];
}

- (BOOL)facebookInputsGood
{
  if (self.signup_facebook_view.email_field.text.isEmail &&
      self.signup_facebook_view.fullname_field.text.length >= 3)
  {
    self.signup_facebook_view.next_button.enabled = YES;
    self.signup_facebook_view.next_button.hidden = NO;
    return YES;
  }
  else
  {
    self.signup_facebook_view.next_button.hidden = YES;
    self.signup_facebook_view.next_button.enabled = NO;
    return NO;
  }
}

- (void)facebookEmailTextChanged:(id)sender
{
  if (self.signup_facebook_view.email_field.text.length == 0)
  {
    self.signup_facebook_view.email_image.image = [UIImage imageNamed:@"icon-email"];
  }
  [self checkFacebookInputs];
}

- (void)facebookEmailTextEditingEnded:(id)sender
{
  NSCharacterSet* white_space = [NSCharacterSet whitespaceCharacterSet];
  self.signup_facebook_view.email_field.text =
  [self.signup_facebook_view.email_field.text stringByTrimmingCharactersInSet:white_space];
  if (self.signup_facebook_view.email_field.text.isEmail)
  {
    self.signup_facebook_view.email_image.image = [UIImage imageNamed:@"icon-email-valid"];
    self.signup_facebook_view.error_label.hidden = YES;
  }
  else
  {
    self.signup_facebook_view.email_image.image = [UIImage imageNamed:@"icon-email-error"];
    self.signup_facebook_view.error_label.text = NSLocalizedString(@"Email not valid.", nil);
    self.signup_facebook_view.error_label.hidden = NO;
  }
}

- (void)facebookFullnameTextChanged:(id)sender
{
  if (self.signup_facebook_view.fullname_field.text.length == 0)
  {
    self.signup_facebook_view.fullname_image.image = [UIImage imageNamed:@"icon-fullname"];
  }
  self.signup_facebook_view.error_label.hidden = YES;
  [self checkFacebookInputs];
}

- (void)facebookFullnameTextEditingEnded:(id)sender
{
  NSCharacterSet* white_space = [NSCharacterSet whitespaceCharacterSet];
  self.signup_facebook_view.fullname_field.text =
  [self.signup_facebook_view.fullname_field.text stringByTrimmingCharactersInSet:white_space];
  if (self.signup_facebook_view.fullname_field.text.length < 3)
  {
    self.signup_facebook_view.fullname_image.image = [UIImage imageNamed:@"icon-fullname-error"];
    self.signup_facebook_view.error_label.text =
      NSLocalizedString(@"Name must be at least 3 chars.", nil);
    self.signup_facebook_view.error_label.hidden = NO;
  }
  else
  {
    self.signup_facebook_view.fullname_image.image = [UIImage imageNamed:@"icon-fullname-valid"];
  }
}

- (void)checkRegisterInputs
{
  [self registerInputsGood];
}

- (BOOL)registerInputsGood
{
  if (self.signup_form_view.email_field.text.isEmail &&
      self.signup_form_view.fullname_field.text.length >= 3 &&
      self.signup_form_view.password_field.text.length >= 3)
  {
    self.signup_form_view.next_button.enabled = YES;
    self.signup_form_view.next_button.hidden = NO;
    return YES;
  }
  else
  {
    self.signup_form_view.next_button.hidden = YES;
    self.signup_form_view.next_button.enabled = NO;
    return NO;
  }
}

- (void)signupEmailTextChanged:(id)sender
{
  if (self.signup_form_view.email_field.text.length == 0)
  {
    self.signup_form_view.email_image.image = [UIImage imageNamed:@"icon-email"];
  }
  [self checkRegisterInputs];
}

- (void)signupEmailTextEditingEnded:(id)sender
{
  NSCharacterSet* white_space = [NSCharacterSet whitespaceCharacterSet];
  self.signup_form_view.email_field.text =
    [self.signup_form_view.email_field.text stringByTrimmingCharactersInSet:white_space];
  if (self.signup_form_view.email_field.text.isEmail)
  {
    self.signup_form_view.email_image.image = [UIImage imageNamed:@"icon-email-valid"];
    self.signup_form_view.error_label.hidden = YES;
  }
  else
  {
    self.signup_form_view.email_image.image = [UIImage imageNamed:@"icon-email-error"];
    self.signup_form_view.error_label.text = NSLocalizedString(@"Email not valid.", nil);
    self.signup_form_view.error_label.hidden = NO;
  }
}

- (void)signupFullnameTextChanged:(id)sender
{
  if (self.signup_form_view.fullname_field.text.length == 0)
  {
    self.signup_form_view.fullname_image.image = [UIImage imageNamed:@"icon-fullname"];
  }
  self.signup_form_view.error_label.hidden = YES;
  [self checkRegisterInputs];
}

- (void)signupFullnameTextEditingEnded:(id)sender
{
  NSCharacterSet* white_space = [NSCharacterSet whitespaceCharacterSet];
  self.signup_form_view.fullname_field.text =
    [self.signup_form_view.fullname_field.text stringByTrimmingCharactersInSet:white_space];
  if (self.signup_form_view.fullname_field.text.length < 3)
  {
    self.signup_form_view.fullname_image.image = [UIImage imageNamed:@"icon-fullname-error"];
    self.signup_form_view.error_label.text =
      NSLocalizedString(@"Name must be at least 3 chars.", nil);
    self.signup_form_view.error_label.hidden = NO;
  }
  else
  {
    self.signup_form_view.fullname_image.image = [UIImage imageNamed:@"icon-fullname-valid"];
  }
}

- (void)signupPasswordTextChanged:(id)sender
{
  if (self.signup_form_view.password_field.text.length == 0)
  {
    self.signup_form_view.password_image.image = [UIImage imageNamed:@"icon-password"];
  }
  self.signup_form_view.error_label.hidden = YES;
  [self checkRegisterInputs];
}

- (void)signupPasswordTextEditingEnded:(id)sender
{
  if (self.signup_form_view.password_field.text.length < 3)
  {
    self.signup_form_view.password_image.image = [UIImage imageNamed:@"icon-password-error"];
    self.signup_form_view.error_label.text =
      NSLocalizedString(@"Password must be at least 3 characters.", nil);
    self.signup_form_view.error_label.hidden = NO;
  }
  else
  {
    self.signup_form_view.password_image.image = [UIImage imageNamed:@"icon-password-valid"];
  }
}

- (void)legalLinkTapped:(id)sender
{
  NSURL* url = [NSURL URLWithString:INFINIT_LEGAL_URL];
  [[UIApplication sharedApplication] openURL:url];
}

#pragma mark - Keyboard

- (void)keyboardWillShow:(NSNotification*)notification
{
  CGSize keyboard_size =
    [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;

  CGFloat delta = -keyboard_size.height;
  if ([InfinitHostDevice smallScreen])
  {
    delta += 70.0f;
  }
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

- (void)textDidChange:(NSNotification*)notification
{
  UITextField* text_field = notification.object;
  if (text_field == self.login_form_view.password_field)
    self.login_form_view.forgot_button.hidden = (text_field.text.length > 0);
}

- (BOOL)textFieldShouldReturn:(UITextField*)textField
{
  if (textField == self.signup_form_view.email_field)
  {
    [self.signup_form_view.fullname_field becomeFirstResponder];
  }
  else if (textField == self.signup_form_view.fullname_field)
  {
    [self.signup_form_view.password_field becomeFirstResponder];
  }
  else if (textField == self.signup_form_view.password_field)
  {
    [self tryRegister];
  }
  else if (textField == self.signup_facebook_view.email_field)
  {
    [self.signup_facebook_view.fullname_field becomeFirstResponder];
  }
  else if (textField == self.signup_facebook_view.fullname_field)
  {
    [self tryFacebookRegister];
  }
  else if (textField == self.login_form_view.email_field)
  {
    [self.login_form_view.password_field becomeFirstResponder];
  }
  else if (textField == self.login_form_view.password_field)
  {
    [self tryLogin];
  }
  return YES;
}

#pragma mark - Login/Register

- (void)tryLogin
{
  if (_logging_in)
    return;
  if ([InfinitConnectionManager sharedInstance].network_status == InfinitNetworkStatusNotReachable)
  {
    self.login_form_view.error_label.text =
      NSLocalizedString(@"Ensure you're connected to the Internet.", nil);
    self.login_form_view.error_label.hidden = NO;
    self.login_form_view.next_button.enabled = YES;
    return;
  }
  _logging_in = YES;
  self.login_form_view.error_label.hidden = YES;
  self.login_form_view.facebook_button.enabled = NO;
  if ([self loginInputsGood])
  {
    [self.view endEditing:YES];
    [self keyboardEntryDone];
    self.login_form_view.next_button.hidden = YES;
    [self.login_form_view.activity startAnimating];
    self.login_form_view.email_field.enabled = NO;
    self.login_form_view.password_field.enabled = NO;
    self.login_form_view.back_button.enabled = NO;
    NSCharacterSet* white_space = [NSCharacterSet whitespaceCharacterSet];
    NSString* email =
      [self.login_form_view.email_field.text stringByTrimmingCharactersInSet:white_space];
    [[InfinitStateManager sharedInstance] login:email
                                       password:self.login_form_view.password_field.text
                                performSelector:@selector(loginCallback:)
                                       onObject:self];
  }
  else
  {
    self.login_form_view.next_button.enabled = YES;
  }
}

- (void)tryFacebookLogin
{
  if (_logging_in)
    return;
  if ([InfinitConnectionManager sharedInstance].network_status == InfinitNetworkStatusNotReachable)
  {
    self.login_form_view.error_label.text =
    NSLocalizedString(@"Ensure you're connected to the Internet.", nil);
    self.login_form_view.error_label.hidden = NO;
    self.login_form_view.next_button.enabled = YES;
    return;
  }
  _logging_in = YES;
  self.login_form_view.error_label.hidden = YES;
  self.login_form_view.facebook_button.enabled = NO;
  NSString* token = FBSession.activeSession.accessTokenData.accessToken;
  [[InfinitStateManager sharedInstance] facebookConnect:token
                                           emailAddress:nil
                                        performSelector:@selector(loginCallback:)
                                               onObject:self];
}

- (void)loginCallback:(InfinitStateResult*)result
{
  _logging_in = NO;
  self.login_form_view.next_button.hidden = NO;
  [self.login_form_view.activity stopAnimating];
  if (result.success)
  {
    _username = [self.login_form_view.email_field.text copy];
    _password = [self.login_form_view.password_field.text copy];
    self.login_form_view.password_field.text = nil;
    [self onSuccessfulLogin];
    UIStoryboard* storyboard =
      [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
    UIViewController* view_controller =
      [storyboard instantiateViewControllerWithIdentifier:@"tab_bar_controller"];
    [self presentViewController:view_controller animated:YES completion:nil];
  }
  else
  {
    self.login_form_view.email_field.enabled = YES;
    self.login_form_view.password_field.enabled = YES;
    self.login_form_view.back_button.enabled = YES;
    self.login_form_view.error_label.text = [self registerLoginErrorFromStatus:result.status];
    self.login_form_view.error_label.hidden = NO;
    if (result.status == gap_email_password_dont_match)
      self.login_form_view.forgot_button.hidden = NO;
    self.login_form_view.facebook_button.enabled = YES;
  }
}

- (void)onSuccessfulLogin
{
  [InfinitDeviceManager sharedInstance];
  [InfinitUserManager sharedInstance];
  [InfinitPeerTransactionManager sharedInstance];
  [InfinitDownloadFolderManager sharedInstance];
  [InfinitBackgroundManager sharedInstance];
  [InfinitRatingManager sharedInstance];

  NSString* old_account = [InfinitApplicationSettings sharedInstance].username;
  if (![old_account isEqualToString:_username])
  {
    if ([[InfinitKeychain sharedInstance] credentialsForAccountInKeychain:old_account])
    {
      [[InfinitKeychain sharedInstance] removeAccount:old_account];
    }
  }
  [[InfinitApplicationSettings sharedInstance] setUsername:_username];
  if (_password)
  {
    if ([[InfinitKeychain sharedInstance] credentialsForAccountInKeychain:_username])
    {
      [[InfinitKeychain sharedInstance] updatePassword:_password forAccount:_username];
    }
    else
    {
      [[InfinitKeychain sharedInstance] addPassword:_password forAccount:_username];
    }
  }
  _password = nil;
}

- (NSString*)registerLoginErrorFromStatus:(gap_Status)status
{
  switch (status)
  {
    case gap_already_logged_in:
      return NSLocalizedString(@"You're already logged in.", nil);
    case gap_deprecated:
      return NSLocalizedString(@"Version not supported, please update.", nil);
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
      return NSLocalizedString(@"Our Server is down. Thanks for being patient.", nil);
    case gap_password_not_valid:
      return NSLocalizedString(@"Password not valid.", nil);

    default:
      return [NSString stringWithFormat:@"%@: %d", NSLocalizedString(@"Unknown login error", nil),
              status];
  }
}

- (void)tryFacebookRegister
{
  if (_registering)
    return;
  if ([InfinitConnectionManager sharedInstance].network_status == InfinitNetworkStatusNotReachable)
  {
    self.signup_facebook_view.error_label.text =
      NSLocalizedString(@"Ensure you're connected to the Internet.", nil);
    self.signup_facebook_view.error_label.hidden = NO;
    self.signup_facebook_view.next_button.enabled = YES;
    return;
  }
  _registering = YES;
  self.signup_facebook_view.error_label.hidden = YES;
  if ([self facebookInputsGood])
  {
    [self.view endEditing:YES];
    [self keyboardEntryDone];
    self.signup_facebook_view.next_button.hidden = YES;
    [self.signup_facebook_view.activity startAnimating];
    self.signup_facebook_view.email_field.enabled = NO;
    self.signup_facebook_view.fullname_field.enabled = NO;
    self.signup_facebook_view.back_button.enabled = NO;
    NSCharacterSet* white_space = [NSCharacterSet whitespaceCharacterSet];
    NSString* email =
      [self.signup_facebook_view.email_field.text stringByTrimmingCharactersInSet:white_space];
    NSString* facebook_token = FBSession.activeSession.accessTokenData.accessToken;
    [[InfinitStateManager sharedInstance] facebookConnect:facebook_token
                                             emailAddress:email
                                          performSelector:@selector(facebookConnectRegisterCallback:)
                                                 onObject:self];
  }
  else
  {
    self.signup_facebook_view.next_button.enabled = YES;
  }
}

- (void)facebookConnectRegisterCallback:(InfinitStateResult*)result
{
  _registering = NO;
  self.signup_facebook_view.next_button.hidden = NO;
  [self.signup_facebook_view.activity stopAnimating];
  if (result.success)
  {
    _password = nil;
    NSCharacterSet* white_space = [NSCharacterSet whitespaceCharacterSet];
    NSString* fullname =
      [self.signup_facebook_view.fullname_field.text stringByTrimmingCharactersInSet:white_space];
    [self onSuccessfulLogin];
    if (self.avatar_image != nil)
    {
      [[InfinitStateManager sharedInstance] setSelfAvatar:self.avatar_image
                                          performSelector:NULL
                                                 onObject:nil];
    }
    if (![fullname isEqualToString:self.facebook_user.fullname])
    {
      [[InfinitStateManager sharedInstance] setSelfFullname:fullname
                                            performSelector:NULL 
                                                   onObject:nil];
    }
    [self performSegueWithIdentifier:@"register_invitation_code_segue" sender:self];
  }
  else
  {
    self.signup_facebook_view.email_field.enabled = YES;
    self.signup_facebook_view.fullname_field.enabled = NO;
    self.signup_facebook_view.back_button.enabled = YES;
    self.signup_facebook_view.error_label.text = [self registerLoginErrorFromStatus:result.status];
    self.signup_facebook_view.error_label.hidden = NO;
  }
}

- (void)tryRegister
{
  if (_registering)
    return;
  if ([InfinitConnectionManager sharedInstance].network_status == InfinitNetworkStatusNotReachable)
  {
    self.signup_form_view.error_label.text =
      NSLocalizedString(@"Ensure you're connected to the Internet.", nil);
    self.signup_form_view.error_label.hidden = NO;
    self.signup_form_view.next_button.enabled = YES;
    return;
  }
  _registering = YES;
  self.signup_form_view.error_label.hidden = YES;
  if ([self registerInputsGood])
  {
    [self.view endEditing:YES];
    [self keyboardEntryDone];
    self.signup_form_view.next_button.hidden = YES;
    [self.signup_form_view.activity startAnimating];
    self.signup_form_view.email_field.enabled = NO;
    self.signup_form_view.fullname_field.enabled = NO;
    self.signup_form_view.password_field.enabled = NO;
    self.signup_form_view.back_button.enabled = NO;
    NSCharacterSet* white_space = [NSCharacterSet whitespaceCharacterSet];
    NSString* email =
      [self.signup_form_view.email_field.text stringByTrimmingCharactersInSet:white_space];
    NSString* fullname =
      [self.signup_form_view.fullname_field.text stringByTrimmingCharactersInSet:white_space];
    [[InfinitStateManager sharedInstance] registerFullname:fullname
                                                     email:email
                                                  password:self.signup_form_view.password_field.text
                                           performSelector:@selector(registerCallback:)
                                                  onObject:self];
  }
  else
  {
    self.signup_form_view.next_button.enabled = YES;
  }
}

- (void)registerCallback:(InfinitStateResult*)result
{
  _registering = NO;
  self.signup_form_view.next_button.hidden = NO;
  [self.signup_form_view.activity stopAnimating];
  if (result.success)
  {
    _username = [self.signup_form_view.email_field.text copy];
    _password = [self.signup_form_view.password_field.text copy];
    self.signup_form_view.password_field.text = nil;
    [self onSuccessfulLogin];
    if (self.avatar_image != nil)
    {
      [[InfinitStateManager sharedInstance] setSelfAvatar:self.avatar_image
                                          performSelector:NULL
                                                 onObject:nil];
    }
    [self performSegueWithIdentifier:@"register_invitation_code_segue" sender:self];
  }
  else
  {
    self.signup_form_view.email_field.enabled = YES;
    self.signup_form_view.fullname_field.enabled = NO;
    self.signup_form_view.password_field.enabled = YES;
    self.signup_form_view.back_button.enabled = YES;
    self.signup_form_view.error_label.text = [self registerLoginErrorFromStatus:result.status];
    self.signup_form_view.error_label.hidden = NO;
  }
}

#pragma mark - Avatar Picker

- (void)avatarButtonTapped:(id)sender
{
  UIActionSheet* actionSheet =
    [[UIActionSheet alloc] initWithTitle:nil
                                delegate:self
                       cancelButtonTitle:NSLocalizedString(@"Back", nil)
                  destructiveButtonTitle:nil
                       otherButtonTitles:NSLocalizedString(@"Take new photo", nil),
                                         NSLocalizedString(@"Choose a photo...", nil), nil];
  [actionSheet showInView:self.view];
}

- (void)actionSheet:(UIActionSheet*)actionSheet
didDismissWithButtonIndex:(NSInteger)buttonIndex
{
  NSString* choice = [actionSheet buttonTitleAtIndex:buttonIndex];
  if([choice isEqualToString:NSLocalizedString(@"Choose a photo...", nil)])
  {
    [self presentImagePicker:UIImagePickerControllerSourceTypeSavedPhotosAlbum];
  }
  if([choice isEqualToString:NSLocalizedString(@"Take new photo", nil)])
  {
    [self presentImagePicker:UIImagePickerControllerSourceTypeCamera];
  }
}

- (void)presentImagePicker:(UIImagePickerControllerSourceType)sourceType
{
  if (self.picker == nil)
    self.picker = [[UIImagePickerController alloc] init];
  self.picker.view.tintColor = [UIColor blackColor];
  self.picker.sourceType = sourceType;
  self.picker.mediaTypes = @[(NSString*)kUTTypeImage];
  self.picker.allowsEditing = YES;
  self.picker.delegate = self;
  if (sourceType == UIImagePickerControllerSourceTypeCamera)
  {
    self.picker.cameraDevice = UIImagePickerControllerCameraDeviceFront;
  }
  [self presentViewController:self.picker animated:YES completion:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController*)picker
{
  [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController*)picker
didFinishPickingMediaWithInfo:(NSDictionary*)info
{
  self.avatar_image = info[UIImagePickerControllerEditedImage];
  self.signup_form_view.avatar_button.titleEdgeInsets = UIEdgeInsetsMake(0.0f, 0.0f, 0.0f, 0.0f);
  self.signup_form_view.avatar_button.imageEdgeInsets = UIEdgeInsetsMake(0.0f, 0.0f, 0.0f, 0.0f);
  self.signup_facebook_view.avatar_button.titleEdgeInsets = UIEdgeInsetsMake(0.0f, 0.0f, 0.0f, 0.0f);
  self.signup_facebook_view.avatar_button.imageEdgeInsets = UIEdgeInsetsMake(0.0f, 0.0f, 0.0f, 0.0f);

  self.signup_form_view.avatar = self.avatar_image;
  self.signup_facebook_view.avatar = self.avatar_image;
  
  [self.picker dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Connection Status

- (void)connectionTypeChanged:(NSNotification*)notification
{
  InfinitNetworkStatuses network_status = [notification.userInfo[@"connection_type"] integerValue];
  if (network_status == InfinitNetworkStatusNotReachable)
  {
    __weak UILabel* label = nil;
    if (_logging_in)
      label = self.login_form_view.error_label;
    else if (_registering)
      label = self.signup_form_view.error_label;
    else
      return;
    label.text = NSLocalizedString(@"Ensure you're connected to the Internet.", nil);
    label.hidden = NO;
  }
}

#pragma mark - Storyboard

- (void)prepareForSegue:(UIStoryboardSegue*)segue
                 sender:(id)sender
{
  if ([segue.identifier isEqualToString:@"register_invitation_code_segue"])
  {
    InfinitLoginInvitationCodeController* dest_vc =
      (InfinitLoginInvitationCodeController*)segue.destinationViewController;
    dest_vc.login_mode = YES;
  }
}

#pragma mark - Facebook Handling

- (void)facebookSessionStateChanged:(NSNotification*)notification
{
  if (![[NSThread currentThread] isEqual:[NSThread mainThread]])
  {
    [self performSelectorOnMainThread:@selector(facebookSessionStateChanged:)
                           withObject:notification 
                        waitUntilDone:NO];
    return;
  }
  FBSessionState state = [notification.userInfo[@"state"] unsignedIntegerValue];
  NSError* error = notification.userInfo[@"error"];
  [self.signup_facebook_view.activity stopAnimating];
  [self.login_form_view.activity stopAnimating];
  if (state == FBSessionStateOpen || state == FBSessionStateOpenTokenExtended)
  {
    if (self.facebook_connect_type == InfinitFacebookConnectRegister)
    {
      [[FBRequest requestForMe] startWithCompletionHandler:^(FBRequestConnection* connection,
                                                             NSDictionary<FBGraphUser>* fb_user,
                                                             NSError* error)
       {
         UIImage* avatar = nil;
         NSString* email = nil;
         NSString* fullname = nil;
         if (error)
         {
         }
         else
         {
           NSData* avatar_data =
             [NSData dataWithContentsOfURL:[self avatarURLForUserWithId:fb_user.objectID]];
           avatar = [UIImage imageWithData:avatar_data];
           email = fb_user[@"email"];
           fullname = fb_user.name;
         }
         _facebook_user = [InfinitFacebookUser userWithAvatar:avatar
                                                        email:email
                                                     fullname:fullname];
         [self performSelectorOnMainThread:@selector(updateFacebookUser)
                                withObject:nil
                             waitUntilDone:NO];
       }];
    }
    else if (self.facebook_connect_type == InfinitFacebookConnectLogin)
    {
      [self tryFacebookLogin];
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:INFINIT_FACEBOOK_SESSION_STATE_CHANGED
                                                  object:nil];
  }
  else if (state == FBSessionStateClosedLoginFailed || error)
  {
    NSString* title = NSLocalizedString(@"Unable to login with Facebook", nil);
    NSString* message = nil;
    if (error)
    {
      message = error.localizedDescription;
    }
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:title
                                                    message:message
                                                   delegate:self
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
  }
}

- (void)updateFacebookUser
{
  self.signup_facebook_view.avatar = self.facebook_user.avatar;
  self.signup_facebook_view.fullname_field.text = self.facebook_user.fullname;
  self.signup_facebook_view.email_field.text = self.facebook_user.email;
  self.signup_facebook_view.fullname_field.enabled = YES;
  self.signup_facebook_view.email_field.enabled = YES;
  [self checkFacebookInputs];
}

- (NSURL*)avatarURLForUserWithId:(NSString*)id_
{
  NSString* str =
    [NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=large", id_];
  return [NSURL URLWithString:str];
}

@end
