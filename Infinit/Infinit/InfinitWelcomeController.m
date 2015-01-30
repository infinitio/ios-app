//
//  InfinitWelcomeController.m
//  Infinit
//
//  Created by Michael Dee on 12/14/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import "InfinitWelcomeController.h"

#import "AppDelegate.h"

#import <Gap/InfinitPeerTransactionManager.h>
#import <Gap/InfinitStateManager.h>
#import <Gap/InfinitStateResult.h>
#import <Gap/InfinitUserManager.h>

//#import <FacebookSDK/FacebookSDK.h>

#import <MobileCoreServices/MobileCoreServices.h>

#import "InfinitApplicationSettings.h"
#import "InfinitBackgroundManager.h"
#import "InfinitColor.h"
#import "InfinitDownloadFolderManager.h"
#import "InfinitHostDevice.h"
#import "InfinitKeychain.h"
#import "WelcomeLoginFormView.h"
#import "WelcomeSignupFormView.h"

#import "NSString+email.h"

@interface InfinitWelcomeController () <UITextFieldDelegate,
                                        UIActionSheetDelegate,
                                        UIImagePickerControllerDelegate,
                                        UINavigationControllerDelegate>

@property (nonatomic, strong) WelcomeLoginFormView* login_form_view;
@property (nonatomic, strong) WelcomeSignupFormView* signup_form_view;

@property (nonatomic, weak) IBOutlet UIImageView* logo_image_view;
@property (nonatomic, weak) IBOutlet UIImageView* balloon_image_view;

@property (nonatomic, weak) IBOutlet UIButton* signup_with_facebook_button;
@property (nonatomic, weak) IBOutlet UIButton* signup_with_email_button;
@property (nonatomic, weak) IBOutlet UIButton* login_button;
@property (nonatomic, weak) IBOutlet UILabel* tagline;

@property (nonatomic, strong) UIImage* avatar_image;
@property (nonatomic, strong) UIImagePickerController* picker;

@end

@implementation InfinitWelcomeController
{
@private
  NSString* _password;
  NSString* _username;

  BOOL _logging_in;
  BOOL _registering;
}

- (BOOL)shouldAutorotate
{
  return NO;
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
  [self configureSignupView];

  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(keyboardWillShow:)
                                               name:UIKeyboardWillShowNotification
                                             object:nil];
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
    password = nil;
    [self checkLoginInputs];
  }
  [super viewDidAppear:animated];
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
                                           action:@selector(facebookButtonTapped:)
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
                                          action:@selector(registerAvatarButtonTapped:)
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

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Button Handling

- (IBAction)facebookButtonTapped:(id)sender
{
  UIAlertView* alert = [[UIAlertView alloc] initWithTitle:nil
                                                  message:@"Computer says no"
                                                 delegate:nil
                                        cancelButtonTitle:@"Back"
                                        otherButtonTitles:nil];
  [alert show];
//  self.signup_with_facebook_button.enabled = NO;
//
//  // Open a session showing the user the login UI
//  // You must ALWAYS ask for public_profile permissions when opening a session
//  [FBSession openActiveSessionWithReadPermissions:@[@"public_profile", @"email", @"user_friends", @"user_birthday"]
//                                     allowLoginUI:YES
//                                completionHandler:
//   ^(FBSession *session, FBSessionState state, NSError *error) {
//     
//     // Retrieve the app delegate
//     AppDelegate *appDelegate = (AppDelegate*)[UIApplication sharedApplication].delegate;
//     // Call the app delegate's sessionStateChanged:state:error method to handle session state changes
//     [appDelegate sessionStateChanged:session state:state error:error];
//   }];
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

- (void)registerNextButtonTapped:(id)sender
{
  self.signup_form_view.next_button.enabled = NO;
  [self tryRegister];
}

#pragma mark - Input Checks

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

- (void)checkRegisterInputs
{
  [self registerInputsGood];
}

- (BOOL)registerInputsGood
{
  if (self.signup_form_view.email_field.text.isEmail &&
      self.signup_form_view.fullname_field.text.length >= 3 &&
      self.signup_form_view.password_field.text.length > 3)
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
      NSLocalizedString(@"Password must be at least 3 chars.", nil);
    self.signup_form_view.error_label.hidden = NO;
  }
  else
  {
    self.signup_form_view.password_image.image = [UIImage imageNamed:@"icon-password-valid"];
  }
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
  _logging_in = YES;
  self.login_form_view.error_label.hidden = YES;
//  self.login_form_view.facebook_hidden = YES;
  if ([self loginInputsGood])
  {
    [self.view endEditing:YES];
    [self keyboardEntryDone];
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

- (void)loginCallback:(InfinitStateResult*)result
{
  _logging_in = NO;
  [self.login_form_view.activity stopAnimating];
  if (result.success)
  {
    _username = [self.login_form_view.email_field.text copy];
    _password = [self.login_form_view.password_field.text copy];
    self.login_form_view.password_field.text = nil;
    [self onSuccessfulLogin];
  }
  else
  {
    self.login_form_view.email_field.enabled = YES;
    self.login_form_view.password_field.enabled = YES;
    self.login_form_view.back_button.enabled = YES;
    self.login_form_view.error_label.text = [self registerLoginErrorFromStatus:result.status];
    self.login_form_view.error_label.hidden = NO;
//    self.login_form_view.facebook_hidden = NO;
  }
}

- (void)onSuccessfulLogin
{
  [InfinitUserManager sharedInstance];
  [InfinitPeerTransactionManager sharedInstance];
  [InfinitDownloadFolderManager sharedInstance];
  [InfinitBackgroundManager sharedInstance];

  NSString* old_account = [[InfinitApplicationSettings sharedInstance] username];
  if (![old_account isEqualToString:_username])
  {
    if ([[InfinitKeychain sharedInstance] credentialsForAccountInKeychain:old_account])
    {
      [[InfinitKeychain sharedInstance] removeAccount:old_account];
    }
  }
  [[InfinitApplicationSettings sharedInstance] setUsername:_username];
  if ([[InfinitKeychain sharedInstance] credentialsForAccountInKeychain:_username])
  {
    [[InfinitKeychain sharedInstance] updatePassword:_password forAccount:_username];
  }
  else
  {
    [[InfinitKeychain sharedInstance] addPassword:_password forAccount:_username];
  }
  _password = nil;

  UIStoryboard* storyboard =
    [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
  UIViewController* view_controller =
    [storyboard instantiateViewControllerWithIdentifier:@"tab_bar_controller"];
  [self presentViewController:view_controller animated:YES completion:nil];
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

- (void)tryRegister
{
  if (_registering)
    return;
  _registering = YES;
  self.signup_form_view.error_label.hidden = YES;
  if ([self registerInputsGood])
  {
    [self.view endEditing:YES];
    [self keyboardEntryDone];
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

- (void)registerAvatarButtonTapped:(id)sender
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

  [self.signup_form_view setAvatar:self.avatar_image];
  
  [self.picker dismissViewControllerAnimated:YES completion:nil];
}


- (BOOL)prefersStatusBarHidden
{
  return YES;
}

@end
