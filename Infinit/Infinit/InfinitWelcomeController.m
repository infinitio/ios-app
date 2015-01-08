//
//  InfinitWelcomeController.m
//  Infinit
//
//  Created by Michael Dee on 12/14/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import "InfinitWelcomeController.h"

#import "AppDelegate.h"

#import <MobileCoreServices/MobileCoreServices.h>

#import <Gap/InfinitUtilities.h>
#import <Gap/InfinitPeerTransactionManager.h>
#import <Gap/InfinitStateManager.h>
#import <Gap/InfinitStateResult.h>
#import <Gap/InfinitUserManager.h>

#import <FacebookSDK/FacebookSDK.h>

#import "WelcomeLoginFormView.h"
#import "WelcomeSignupFormView.h"

#import "InfinitColor.h"


@interface InfinitWelcomeController () <UITextFieldDelegate,
                                        UIActionSheetDelegate,
                                        UIImagePickerControllerDelegate,
                                        UINavigationControllerDelegate>

//@property (weak, nonatomic) IBOutlet UIView* signupFormView;
@property (strong, nonatomic) WelcomeLoginFormView* login_form_view;
@property (strong, nonatomic) WelcomeSignupFormView* signup_form_view;

@property (weak, nonatomic) IBOutlet UIImageView* logo_image_view;
@property (weak, nonatomic) IBOutlet UIImageView* balloon_image_view;

@property (weak, nonatomic) IBOutlet UIButton* signup_with_facebook_button;
@property (weak, nonatomic) IBOutlet UIButton* signup_with_email_button;
@property (weak, nonatomic) IBOutlet UIButton* login_button;
@property (weak, nonatomic) IBOutlet UILabel* tagline;

@property (strong, nonatomic) UIImage* avatar_image;
@property (strong, nonatomic) UIImagePickerController* picker;

@property BOOL showing_login_form;

@end

@implementation InfinitWelcomeController

- (void)awakeFromNib
{}

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

  self.signup_with_facebook_button.layer.cornerRadius = 3.0f;
  self.signup_with_email_button.layer.cornerRadius = 3.0f;
  self.login_button.layer.cornerRadius = 3.0f;

  [self configureLoginView];

//  self.signup_form_view = [[[UINib nibWithNibName:@"WelcomeSignupFormView" bundle:nil] instantiateWithOwner:self options:nil] objectAtIndex:0];
//  self.signup_form_view.frame = CGRectMake(0, self.view.frame.size.height, self.view.frame.size.width, 600);
//  [self.view addSubview:self.signup_form_view];

//  [self.signup_form_view.back_button addTarget:self
//                                        action:@selector(signupBackButtonSelected)
//                              forControlEvents:UIControlEventTouchUpInside];
//  [self.signup_form_view.back_button addTarget:self
//                                        action:@selector(loginBackButtonTouched)
//                              forControlEvents:UIControlEventTouchUpInside];
//  
//  [self.signup_form_view.avatar_button addTarget:self
//                                      action:@selector(addAvatarButtonClicked:)
//                            forControlEvents:UIControlEventTouchUpInside];

  self.showing_login_form = NO;
//  
//  self.signup_with_email_button.titleLabel.font = [UIFont fontWithName:@"SourceSansPro-Semibold" size:15];
//  self.login_button.titleLabel.font = [UIFont fontWithName:@"SourceSansPro-Semibold" size:15];
//  self.signup_with_facebook_button.titleLabel.font = [UIFont fontWithName:@"SourceSansPro-Semibold" size:15];

  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(keyboardWillShow:)
                                               name:UIKeyboardWillShowNotification
                                             object:nil];
  self.signup_with_facebook_button.enabled = NO;
  self.signup_with_email_button.enabled = NO;
}

- (void)configureLoginView
{
  UINib* login_nib = [UINib nibWithNibName:@"WelcomeLoginFormView" bundle:nil];
  self.login_form_view = [[login_nib instantiateWithOwner:self options:nil] firstObject];
  [self.view addSubview:self.login_form_view];
  [self.view bringSubviewToFront:self.login_form_view];
  self.login_form_view.frame = CGRectMake(0.0f, self.view.frame.size.height,
                                          self.view.frame.size.width, self.view.frame.size.height);

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
                                       action:@selector(loginBackButtonTapped)
                             forControlEvents:UIControlEventTouchUpInside];
  [self.login_form_view.next_button addTarget:self
                                       action:@selector(loginNextButtonTapped:)
                             forControlEvents:UIControlEventTouchUpInside];
}

- (void)addBalloonParallax
{
  // Set vertical effect
  UIInterpolatingMotionEffect* vertical =
    [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.y"
                                                    type:UIInterpolatingMotionEffectTypeTiltAlongVerticalAxis];
  vertical.minimumRelativeValue = @(-25);
  vertical.maximumRelativeValue = @(25);

  // Set horizontal effect
  UIInterpolatingMotionEffect* horizontal =
    [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.x"
                                                    type:UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis];
  horizontal.minimumRelativeValue = @(-25);
  horizontal.maximumRelativeValue = @(25);

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

#pragma mark Button Handling

- (IBAction)facebookButtonSelected:(id)sender
{
  self.signup_with_facebook_button.enabled = NO;

  // Open a session showing the user the login UI
  // You must ALWAYS ask for public_profile permissions when opening a session
  [FBSession openActiveSessionWithReadPermissions:@[@"public_profile", @"email", @"user_friends", @"user_birthday"]
                                     allowLoginUI:YES
                                completionHandler:
   ^(FBSession *session, FBSessionState state, NSError *error) {
     
     // Retrieve the app delegate
     AppDelegate *appDelegate = (AppDelegate*)[UIApplication sharedApplication].delegate;
     // Call the app delegate's sessionStateChanged:state:error method to handle session state changes
     [appDelegate sessionStateChanged:session state:state error:error];
   }];
}

- (IBAction)signupWithEmailSelected:(id)sender
{
  self.signup_with_email_button.enabled = NO;
  self.signup_form_view.frame = CGRectMake(0,
                                         self.view.frame.size.height,
                                         self.signup_form_view.frame.size.width,
                                         self.signup_form_view.frame.size.height);

  [UIView animateWithDuration:.5
                        delay:.1
       usingSpringWithDamping:.7
        initialSpringVelocity:5
                      options:0
                   animations:^
  {
                     self.signup_form_view.frame = CGRectMake(0,
                                                            self.view.frame.size.height - 310,
                                                            self.signup_form_view.frame.size.width,
                                                            self.signup_form_view.frame.size.height);
                     //Move the balloon and background and logo and label as well.  Put them on a view?
                     
                     
                     
                     
  }
  completion:^(BOOL finished)
  {
    NSLog(@"Happy times");
  }];
   
}

- (IBAction)loginButtonTapped:(id)sender
{
  self.login_button.enabled = NO;
  self.showing_login_form = YES;
  [UIView animateWithDuration:0.5f
                        delay:0.1f
       usingSpringWithDamping:0.7f
        initialSpringVelocity:20.f
                      options:0
                   animations:^
  {
    self.login_form_view.frame =
      CGRectMake(0, self.view.frame.size.height - self.login_form_view.height,
                 self.login_form_view.frame.size.width, self.login_form_view.frame.size.height);

  }
                   completion:^(BOOL finished)
  {
    if (!finished)
    {
      self.login_form_view.frame =
        CGRectMake(0, self.view.frame.size.height - self.login_form_view.height,
                   self.login_form_view.frame.size.width, self.login_form_view.frame.size.height);
    }
  }];
}

- (void)loginBackButtonTapped
{
  self.login_button.enabled = YES;
  self.showing_login_form = NO;

  if (self.view.frame.origin.y != 0.0f)
  {
    [self.view endEditing:YES];
    [UIView animateWithDuration:0.5f
                          delay:0.0f
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
      self.view.frame = CGRectMake(0.0f, 0.0f,
                                   self.view.frame.size.width, self.view.frame.size.height);
    } completion:^(BOOL finished) {
      if (finished)
      {
        [UIView animateWithDuration:0.5f
                              delay:0.0f
                            options:UIViewAnimationOptionCurveEaseInOut animations:^{
          self.login_form_view.frame = CGRectMake(0.0f,
                                                  self.view.frame.size.height,
                                                  self.login_form_view.frame.size.width,
                                                  self.login_form_view.frame.size.height);
        } completion:^(BOOL finished) {
          if (!finished)
          {
            self.login_form_view.frame = CGRectMake(0.0f,
                                                    self.view.frame.size.height,
                                                    self.login_form_view.frame.size.width,
                                                    self.login_form_view.frame.size.height);
          }
        }];
      }
      else
      {
        self.view.frame = CGRectMake(0.0f, 0.0f,
                                     self.view.frame.size.width, self.view.frame.size.height);
        self.login_form_view.frame = CGRectMake(0.0f,
                                                self.view.frame.size.height,
                                                self.login_form_view.frame.size.width,
                                                self.login_form_view.frame.size.height);
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
       self.login_form_view.frame =
       CGRectMake(0, self.view.frame.size.height,
                  self.login_form_view.frame.size.width, self.login_form_view.frame.size.height);

     }
                     completion:^(BOOL finished)
     {
       if (!finished)
       {
         self.login_form_view.frame =
         CGRectMake(0, self.view.frame.size.height,
                    self.login_form_view.frame.size.width, self.login_form_view.frame.size.height);
       }
     }];
  }
}

- (void)loginNextButtonTapped:(id)sender
{
  self.login_form_view.next_button.enabled = NO;
  [self tryLogin];
}

- (void)signupBackButtonSelected
{
//  self.signup_with_email_button.enabled = YES;
//
//  [self.view endEditing:YES];
//  [UIView animateWithDuration:.5
//                        delay:.1
//       usingSpringWithDamping:.7
//        initialSpringVelocity:5
//                      options:0
//                   animations:^
//  {
//                                self.signup_form_view.frame = CGRectMake(0,
//                                 self.view.frame.size.height,
//                                 self.signup_form_view.frame.size.width,
//                                 self.signup_form_view.frame.size.height);
//                                self.balloon_container_view.frame = CGRectMake(0,
//                                                                            0,
//                                                                             self.balloon_container_view.frame.size.width,
//                                                                             self.balloon_container_view.frame.size.height);
//  }
//  completion:^(BOOL finished)
//  {
//    self.balloon_container_top_constraint.constant = 0;
//  }];
}

- (IBAction)addAvatarButtonSelected:(id)sender
{
  
}

#pragma mark Input Checks

- (void)checkLoginInputs
{
  [self loginInputsGood];
}

- (BOOL)loginInputsGood
{
  if ([InfinitUtilities stringIsEmail:self.login_form_view.email_field.text] &&
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
  if ([InfinitUtilities stringIsEmail:self.login_form_view.email_field.text])
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

#pragma mark Keyboard

- (void)keyboardWillShow:(NSNotification*)notification
{
  // Get the size of the keyboard.
  CGSize keyboard_size =
    [[[notification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;

  if (self.showing_login_form)
  {
    [UIView animateWithDuration:0.5f animations:^{
      self.view.frame = CGRectMake(0.0f, -keyboard_size.height,
                                   self.view.frame.size.width, self.view.frame.size.height);
    }];
  }
}

- (BOOL)textFieldShouldReturn:(UITextField*)textField
{
  if (textField == self.signup_form_view.signup_email_textfield)
  {
    [self.signup_form_view.signup_email_textfield becomeFirstResponder];
  }
  else if (textField == self.signup_form_view.signup_fullname_textifeld)
  {
    [self.signup_form_view.signup_fullname_textifeld becomeFirstResponder];
  }
  else if (textField == self.signup_form_view.signup_password_textfield)
  {
    [textField resignFirstResponder];
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

- (void)textInputChanged:(NSNotification*)note
{
  
//  _signupErrorLabel.text = @"Can we change now";

  
  if(note.object == self.signup_form_view.signup_password_textfield)
  {
    NSString* password = self.signup_form_view.signup_password_textfield.text;
    if(password.length < 3)
    {
      
      self.signup_form_view.signup_password_imageview.image = [UIImage imageNamed:@"icon-password-error"];
//      [self.signupErrorLabel setText:@"Your password must be 3 characters min."];
    }
    else
    {
      self.signup_form_view.signup_password_imageview.image = [UIImage imageNamed:@"icon-password-valid"];
    }
  }
  if(note.object == self.signup_form_view.signup_email_textfield)
  {
    NSString* email = self.signup_form_view.signup_email_textfield.text;
    if(![InfinitUtilities stringIsEmail:email])
    {
      self.signup_form_view.signup_email_imageview.image = [UIImage imageNamed:@"icon-email-error"];
//      self.signupErrorLabel.text = @"Email Invalid";
    }
    else
    {
      self.signup_form_view.signup_email_imageview.image = [UIImage imageNamed:@"icon-email-valid"];
    }
  }
  if(note.object == self.signup_form_view.signup_fullname_textifeld)
  {
    NSString* fullname = self.signup_form_view.signup_fullname_textifeld.text;
    if(fullname.length < 3)
    {
      self.signup_form_view.signup_fullname_imageview.image = [UIImage imageNamed:@"icon-fullname-error"];
//      self.signupErrorLabel.text = @"Your name must be 3 characters min.";
    }
    else
    {
      self.signup_form_view.signup_fullname_imageview.image = [UIImage imageNamed:@"icon-fullname-valid"];
    }
  }
  if(note.object == self.login_form_view.email_field)
  {
    NSString* email = self.login_form_view.email_field.text;
    if(![InfinitUtilities stringIsEmail:email])
    {
      self.login_form_view.email_image.image = [UIImage imageNamed:@"icon-email-error"];
      //      self.loginFormView.login_error_label.text = @"Email Invalid";
      
    }
    else
    {
      self.login_form_view.email_image.image = [UIImage imageNamed:@"icon-email-valid"];
    }
  }
  if(note.object == self.login_form_view.password_field)
  {
    NSString* password = self.login_form_view.password_field.text;
    if(password.length < 3)
    {
      
      self.login_form_view.password_image.image = [UIImage imageNamed:@"icon-password-error"];
      //      [self.signupErrorLabel setText:@"Your password must be 3 characters min."];
    }
    else
    {
      self.login_form_view.password_image.image = [UIImage imageNamed:@"icon-password-valid"];
    }
  }
  
  if((self.login_form_view.password_field.text.length >=3 && [InfinitUtilities stringIsEmail:self.login_form_view.email_field.text]))
  {
    //Show next button
    self.login_form_view.next_button.hidden = NO;
  }
  
  if(self.signup_form_view.signup_password_textfield.text.length >=3 && self.signup_form_view.signup_fullname_textifeld.text.length >= 3 && [InfinitUtilities stringIsEmail:self.signup_form_view.signup_email_textfield.text])
  {
    //Show next button
    self.signup_form_view.next_button.hidden = NO;
  }
  
  
}

- (IBAction)signupNextButtonSelected:(id)sender
{
  //Put error if need be.
  NSString* fullname = self.signup_form_view.signup_fullname_textifeld.text;
  NSString* email = self.login_form_view.email_field.text;
  NSString* password = self.login_form_view.password_field.text;
   [[InfinitStateManager sharedInstance] registerFullname:fullname
                                                    email:email
                                                 password:password
                                          performSelector:@selector(loginCallback:)
                                                 onObject:self];
  
}

#pragma mark Login/Register

- (void)tryLogin
{
  self.login_form_view.error_label.hidden = YES;
  if ([self loginInputsGood])
  {
    [self.login_form_view.activity startAnimating];
    self.login_form_view.email_field.enabled = NO;
    self.login_form_view.password_field.enabled = NO;
    self.login_form_view.back_button.enabled = NO;
    [[InfinitStateManager sharedInstance] login:self.login_form_view.email_field.text
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
  [self.login_form_view.activity stopAnimating];
  if (result.success)
  {
    [InfinitUserManager sharedInstance];
    [InfinitPeerTransactionManager sharedInstance];

    UIStoryboard* storyboard =
      [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
    UIViewController* view_controller =
      [storyboard instantiateViewControllerWithIdentifier:@"tabbarcontroller"];
    [self presentViewController:view_controller animated:YES completion:nil];
    self.login_form_view.error_label.hidden = YES;
  }
  else
  {
    self.login_form_view.email_field.enabled = YES;
    self.login_form_view.password_field.enabled = YES;
    self.login_form_view.back_button.enabled = YES;
    NSString* error_str;
    switch (result.status)
    {
      case gap_email_password_dont_match:
        error_str = NSLocalizedString(@"Login/Password don't match.", nil);
        break;
      case gap_already_logged_in:
        error_str = NSLocalizedString(@"You're already logged in.", nil);
        break;
      case gap_email_not_confirmed:
        error_str = NSLocalizedString(@"Your email has not been confirmed.", nil);
        break;
      case gap_handle_already_registered:
        error_str = NSLocalizedString(@"This handle has already been taken.", nil);
        break;
      case gap_meta_down_with_message:
        error_str = NSLocalizedString(@"Our Server is down. Thanks for being patient.", nil);
        break;

      default:
        error_str = [NSString stringWithFormat:@"%@: %d",
                              NSLocalizedString(@"Unknown login error", nil), result.status];
        break;
    }
    self.login_form_view.error_label.text = error_str;
    self.login_form_view.error_label.hidden = NO;
  }
}

#pragma mark ImagePickerFlow
- (void)addAvatarButtonClicked:(id)sender
{
  UIActionSheet* actionSheet =
    [[UIActionSheet alloc] initWithTitle:nil
                                delegate:self
                       cancelButtonTitle:@"Cancel"
                  destructiveButtonTitle:nil
                       otherButtonTitles:@"Take new photo", @"Choose a photo...", nil];
  [actionSheet showInView:self.view];
}

- (void)actionSheet:(UIActionSheet*)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
  NSString* choice =
    [actionSheet buttonTitleAtIndex:buttonIndex];
  if([choice isEqualToString:@"Choose a photo..."])
  {
    [self presentImagePicker:UIImagePickerControllerSourceTypeSavedPhotosAlbum];
  }
  if([choice isEqualToString:@"Take new photo"])
  {
    [self presentImagePicker:UIImagePickerControllerSourceTypeCamera];
  }
}

- (void)presentImagePicker:(UIImagePickerControllerSourceType)sourceType
{
  self.picker =
    [[UIImagePickerController alloc] init];
  self.picker.view.tintColor = [UIColor blackColor];
  self.picker.sourceType = sourceType;
  self.picker.mediaTypes = @[(NSString*)kUTTypeImage];
  self.picker.allowsEditing = YES;
  self.picker.delegate = self;
  //If the source is the camera and not the library of photos.
  if(sourceType == UIImagePickerControllerSourceTypeCamera)
  {
    self.picker.cameraDevice = UIImagePickerControllerCameraDeviceFront;
  }
  //Now Present the Picker
  [self presentViewController:self.picker animated:YES completion:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
  [self dismissViewControllerAnimated:YES completion:nil];
}

//Add a photo to the  Parse Object
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
  self.avatar_image = info[UIImagePickerControllerEditedImage];
  
  self.signup_form_view.avatar_button.titleEdgeInsets = UIEdgeInsetsMake(0.0,
                                                       0.0,
                                                       0.0,
                                                       0.0);
  self.signup_form_view.avatar_button.imageEdgeInsets = UIEdgeInsetsMake(0.0,
                                                       0.0,
                                                       0.0,
                                                       0.0);
  
  [self.signup_form_view.avatar_button setTitle:@"" forState:UIControlStateNormal];
  [self.signup_form_view.avatar_button setImage:self.avatar_image forState:UIControlStateNormal];
  
  [self.picker dismissViewControllerAnimated:YES completion:nil];
}


-(BOOL)prefersStatusBarHidden
{
  return YES;
}

@end
