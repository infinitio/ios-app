//
//  InfinitWelcomeController.m
//  Infinit
//
//  Created by Michael Dee on 12/14/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import "InfinitWelcomeController.h"

#import <MobileCoreServices/MobileCoreServices.h>
#import "AppDelegate.h"

#import <Gap/InfinitUtilities.h>
#import <Gap/InfinitPeerTransactionManager.h>
#import <Gap/InfinitStateManager.h>
#import <Gap/InfinitStateResult.h>
#import <Gap/InfinitUserManager.h>

#import <FacebookSDK/FacebookSDK.h>

#import "WelcomeLoginFormView.h"
#import "WelcomeSignupFormView.h"


@interface InfinitWelcomeController () <UITextFieldDelegate, UIActionSheetDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>

//@property (weak, nonatomic) IBOutlet UIView* signupFormView;
@property (strong, nonatomic) WelcomeLoginFormView* loginFormView;
@property (strong, nonatomic) WelcomeSignupFormView* signupFormView;



@property (weak, nonatomic) IBOutlet UIImageView* logoImageView;
@property (weak, nonatomic) IBOutlet UIImageView* balloonImageView;

@property (weak, nonatomic) IBOutlet UIButton* signUpWithFacebookButton;
@property (weak, nonatomic) IBOutlet UIButton* signupWithEmailButton;
@property (weak, nonatomic) IBOutlet UIButton* loginButton;
@property (weak, nonatomic) IBOutlet UILabel* taglineLabel;


@property (weak, nonatomic) IBOutlet UIView* balloonContainerView;

@property (strong, nonatomic) UIImage* avatar_image;
@property (strong, nonatomic) UIImagePickerController* picker;

@property BOOL showingLoginForm;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *balloonContainerTopConstraint;

@end

@implementation InfinitWelcomeController




- (void)awakeFromNib
{
  
  
  
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  /*
  for (NSString* family in [UIFont familyNames])
  {
    NSLog(@"%@", family);
    
    for (NSString* name in [UIFont fontNamesForFamilyName: family])
    {
      NSLog(@"  %@", name);
    }
  }
   */
  
  self.loginFormView = [[[UINib nibWithNibName:@"WelcomeLoginFormView" bundle:nil] instantiateWithOwner:self options:nil] objectAtIndex:0];
  self.loginFormView.frame = CGRectMake(0, self.view.frame.size.height, self.view.frame.size.width, 600);
  [self.view addSubview:self.loginFormView];
  

  
  self.signupFormView = [[[UINib nibWithNibName:@"WelcomeSignupFormView" bundle:nil] instantiateWithOwner:self options:nil] objectAtIndex:0];
  self.signupFormView.frame = CGRectMake(0, self.view.frame.size.height, self.view.frame.size.width, 600);
  [self.view addSubview:self.signupFormView];
  
  
  [self.signupFormView.back_button addTarget:self
                                     action:@selector(signupBackButtonSelected)
                           forControlEvents:UIControlEventTouchUpInside];
   [self.loginFormView.back_button addTarget:self
                                      action:@selector(loginBackButtonSelected)
                            forControlEvents:UIControlEventTouchUpInside];
  
  [self.signupFormView.avatar_button addTarget:self
                                      action:@selector(addAvatarButtonClicked:)
                            forControlEvents:UIControlEventTouchUpInside];
  
  
  [self addParallax];
  

  self.showingLoginForm = NO;
  
  self.signUpWithFacebookButton.layer.cornerRadius = 5.0;
  self.signupWithEmailButton.layer.cornerRadius = 5.0;
  self.loginButton.layer.cornerRadius = 5.0;
  
  self.signupWithEmailButton.titleLabel.font = [UIFont fontWithName:@"SourceSansPro-Semibold" size:15];
  self.loginButton.titleLabel.font = [UIFont fontWithName:@"SourceSansPro-Semibold" size:15];
  self.signUpWithFacebookButton.titleLabel.font = [UIFont fontWithName:@"SourceSansPro-Semibold" size:15];

  self.taglineLabel.font = [UIFont fontWithName:@"" size:12];

  

  

  
  

  


   


  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(keyboardWillShow:)
                                               name:UIKeyboardWillShowNotification
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(textInputChanged:)
                                               name:UITextFieldTextDidChangeNotification
                                             object:self.signupFormView.signup_fullname_textifeld];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(textInputChanged:)
                                               name:UITextFieldTextDidChangeNotification
                                             object:self.signupFormView.signup_password_textfield];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(textInputChanged:)
                                               name:UITextFieldTextDidChangeNotification
                                             object:self.signupFormView.signup_email_textfield];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(textInputChanged:)
                                               name:UITextFieldTextDidChangeNotification
                                             object:self.loginFormView.login_email_textfield];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(textInputChanged:)
                                               name:UITextFieldTextDidChangeNotification
                                             object:self.loginFormView.login_password_textfield];
}

-  (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self
                                                  name:UITextFieldTextDidChangeNotification
                                                object:self.signupFormView.signup_email_textfield];
  [[NSNotificationCenter defaultCenter] removeObserver:self
                                                  name:UITextFieldTextDidChangeNotification
                                                object:self.signupFormView.signup_fullname_textifeld];
  [[NSNotificationCenter defaultCenter] removeObserver:self
                                                  name:UITextFieldTextDidChangeNotification
                                                object:self.signupFormView.signup_password_textfield];
  [[NSNotificationCenter defaultCenter] removeObserver:self
                                                  name:UITextFieldTextDidChangeNotification
                                                object:self.loginFormView.login_email_textfield];
  [[NSNotificationCenter defaultCenter] removeObserver:self
                                                  name:UITextFieldTextDidChangeNotification
                                                object:self.loginFormView.login_password_textfield];
}

- (IBAction)facebookButtonSelected:(id)sender
{
  self.signUpWithFacebookButton.enabled = NO;

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
  self.signupWithEmailButton.enabled = NO;
  self.signupFormView.frame = CGRectMake(0,
                                         self.view.frame.size.height,
                                         self.signupFormView.frame.size.width,
                                         self.signupFormView.frame.size.height);

  [UIView animateWithDuration:.5
                        delay:.1
       usingSpringWithDamping:.7
        initialSpringVelocity:5
                      options:0
                   animations:^
  {
                     self.signupFormView.frame = CGRectMake(0,
                                                            self.view.frame.size.height - 310,
                                                            self.signupFormView.frame.size.width,
                                                            self.signupFormView.frame.size.height);
                     //Move the balloon and background and logo and label as well.  Put them on a view?
                     
                     
                     
                     
  }
  completion:^(BOOL finished)
  {
    NSLog(@"Happy times");
  }];
   
}

- (void)loginButtonSelected:(id)sender
{
  self.loginButton.enabled = NO;

  self.showingLoginForm = YES;
  self.loginFormView.frame = CGRectMake(0,
                                        self.view.frame.size.height,
                                        self.loginFormView.frame.size.width,
                                        self.loginFormView.frame.size.height);
  [UIView animateWithDuration:.5
                        delay:.1
       usingSpringWithDamping:.7
        initialSpringVelocity:5
                      options:0
                   animations:^
  {
                                self.loginFormView.frame = CGRectMake(0,
                                 self.view.frame.size.height - 310,
                                 self.loginFormView.frame.size.width,
                                 self.loginFormView.frame.size.height);
    
  }
  completion:^(BOOL finished)
  {
  }];
}

- (void)signupBackButtonSelected
{
  self.signupWithEmailButton.enabled = YES;

  [self.view endEditing:YES];
  [UIView animateWithDuration:.5
                        delay:.1
       usingSpringWithDamping:.7
        initialSpringVelocity:5
                      options:0
                   animations:^
  {
                                self.signupFormView.frame = CGRectMake(0,
                                 self.view.frame.size.height,
                                 self.signupFormView.frame.size.width,
                                 self.signupFormView.frame.size.height);
                                self.balloonContainerView.frame = CGRectMake(0,
                                                                            0,
                                                                             self.balloonContainerView.frame.size.width,
                                                                             self.balloonContainerView.frame.size.height);
  }
  completion:^(BOOL finished)
  {
    self.balloonContainerTopConstraint.constant = 0;
  }];
}

- (void)loginBackButtonSelected
{
  self.loginButton.enabled = YES;
  self.showingLoginForm = NO;


  [self.view endEditing:YES];
  [UIView animateWithDuration:.5
                        delay:.1
       usingSpringWithDamping:.7
        initialSpringVelocity:5
                      options:0
                   animations:^
  {
                    self.loginFormView.frame = CGRectMake(0,
                     self.view.frame.size.height,
                     self.loginFormView.frame.size.width,
                     self.loginFormView.frame.size.height);
    
                    self.balloonContainerView.frame = CGRectMake(0,
                                                                 0,
                                                                 self.balloonContainerView.frame.size.width,
                                                                 self.balloonContainerView.frame.size.height);
  }
                   completion:^(BOOL finished)
   {
     self.balloonContainerTopConstraint.constant = 0;
   }];
}
- (IBAction)addAvatarButtonSelected:(id)sender
{
  
}


- (void)keyboardWillShow:(NSNotification*)notification
{
  
  // Get the size of the keyboard.
  CGSize keyboardSize = [[[notification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
  
  //Given size may not account for screen rotation
  int height = MIN(keyboardSize.height,keyboardSize.width);
  int width = MAX(keyboardSize.height,keyboardSize.width);
  
  //your other code here..........
  if(self.showingLoginForm == YES)
  {
    //Move login form up.
    [UIView animateWithDuration:.5
                          delay:.1
         usingSpringWithDamping:.7
          initialSpringVelocity:5
                        options:0
                     animations:^
     {
                       self.loginFormView.frame = CGRectMake(0,
                                            0,
                                            self.loginFormView.frame.size.width,
                                            self.loginFormView.frame.size.height);
                      //Also move the background up with it.
//       self.balloonContainerView.frame = CGRectMake(0,-310,self.balloonContainerView.frame.size.width,self.balloonContainerView.frame.size.height);
      }
                     completion:^(BOOL finished)
     {
//       self.balloonContainerTopConstraint.constant = -310;
     }];
    
  } else
  {
    //Move the signup form up.
    [UIView animateWithDuration:.5
                          delay:.1
         usingSpringWithDamping:.7
          initialSpringVelocity:5
                        options:0
                     animations:^
    {
                      self.signupFormView.frame = CGRectMake(0,
                      0,
                      self.signupFormView.frame.size.width,
                      self.signupFormView.frame.size.height);
//                      self.balloonContainerView.frame = CGRectMake(0,-310,self.balloonContainerView.frame.size.width,self.balloonContainerView.frame.size.height);
    }
                     completion:^(BOOL finished)
     {
//       self.balloonContainerTopConstraint.constant = -310;
     }];
  }
}


//- Text Field Delegate ----------------------------------------------------------------------------
- (void)textFieldDidBeginEditing:(UITextField*)textField
{
  if(textField == self.loginFormView.login_email_textfield || textField == self.loginFormView.login_password_textfield)
  {
    
  }
}



- (void)textFieldDidEndEditing:(UITextField*)textField
{
  
}

- (BOOL)textFieldShouldReturn:(UITextField*)textField
{
  
  //Logic for moving through text fields.
  if (textField == self.signupFormView.signup_email_textfield)
  {
    [self.signupFormView.signup_email_textfield becomeFirstResponder];
  }
  else if (textField == self.signupFormView.signup_fullname_textifeld)
  {
    [self.signupFormView.signup_fullname_textifeld becomeFirstResponder];
  }
  else if (textField == self.signupFormView.signup_password_textfield)
  {
      [textField resignFirstResponder];
  }
  else if (textField == self.loginFormView.login_email_textfield)
  {
    [self.loginFormView.login_password_textfield becomeFirstResponder];
  }
  else if (textField == self.loginFormView.login_password_textfield)
  {
    [textField resignFirstResponder];
  }
  return YES;
}

- (void)textInputChanged:(NSNotification*)note
{
  
//  _signupErrorLabel.text = @"Can we change now";

  
  if(note.object == self.signupFormView.signup_password_textfield)
  {
    NSString* password = self.signupFormView.signup_password_textfield.text;
    if(password.length < 3)
    {
      
      self.signupFormView.signup_password_imageview.image = [UIImage imageNamed:@"icon-password-error"];
//      [self.signupErrorLabel setText:@"Your password must be 3 characters min."];
    }
    else
    {
      self.signupFormView.signup_password_imageview.image = [UIImage imageNamed:@"icon-password-valid"];
    }
  }
  if(note.object == self.signupFormView.signup_email_textfield)
  {
    NSString* email = self.signupFormView.signup_email_textfield.text;
    if(![InfinitUtilities stringIsEmail:email])
    {
      self.signupFormView.signup_email_imageview.image = [UIImage imageNamed:@"icon-email-error"];
//      self.signupErrorLabel.text = @"Email Invalid";
    }
    else
    {
      self.signupFormView.signup_email_imageview.image = [UIImage imageNamed:@"icon-email-valid"];
    }
  }
  if(note.object == self.signupFormView.signup_fullname_textifeld)
  {
    NSString* fullname = self.signupFormView.signup_fullname_textifeld.text;
    if(fullname.length < 3)
    {
      self.signupFormView.signup_fullname_imageview.image = [UIImage imageNamed:@"icon-fullname-error"];
//      self.signupErrorLabel.text = @"Your name must be 3 characters min.";
    }
    else
    {
      self.signupFormView.signup_fullname_imageview.image = [UIImage imageNamed:@"icon-fullname-valid"];
    }
  }
  if(note.object == self.loginFormView.login_email_textfield)
  {
    NSString* email = self.loginFormView.login_email_textfield.text;
    if(![InfinitUtilities stringIsEmail:email])
    {
      self.loginFormView.login_email_imageview.image = [UIImage imageNamed:@"icon-email-error"];
      //      self.loginFormView.login_error_label.text = @"Email Invalid";
      
    }
    else
    {
      self.loginFormView.login_email_imageview.image = [UIImage imageNamed:@"icon-email-valid"];
    }
  }
  if(note.object == self.loginFormView.login_password_textfield)
  {
    NSString* password = self.loginFormView.login_password_textfield.text;
    if(password.length < 3)
    {
      
      self.loginFormView.login_password_imageview.image = [UIImage imageNamed:@"icon-password-error"];
      //      [self.signupErrorLabel setText:@"Your password must be 3 characters min."];
    }
    else
    {
      self.loginFormView.login_password_imageview.image = [UIImage imageNamed:@"icon-password-valid"];
    }
  }
  
  if((self.loginFormView.login_password_textfield.text.length >=3 && [InfinitUtilities stringIsEmail:self.loginFormView.login_email_textfield.text]))
  {
    //Show next button
    self.loginFormView.next_button.hidden = NO;
  }
  
  if(self.signupFormView.signup_password_textfield.text.length >=3 && self.signupFormView.signup_fullname_textifeld.text.length >= 3 && [InfinitUtilities stringIsEmail:self.signupFormView.signup_email_textfield.text])
  {
    //Show next button
    self.signupFormView.next_button.hidden = NO;
  }
  
  
}

- (IBAction)signupNextButtonSelected:(id)sender
{
  //Put error if need be.
  NSString* fullname = self.signupFormView.signup_fullname_textifeld.text;
  NSString* email = self.loginFormView.login_email_textfield.text;
  NSString* password = self.loginFormView.login_password_textfield.text;
   [[InfinitStateManager sharedInstance] registerFullname:fullname
                                                    email:email
                                                 password:password
                                          performSelector:@selector(loginCallback:)
                                                 onObject:self];
  
}

//Isn't connected yet.
- (IBAction)loginnextbuttonSelected:(id)sender
{
  //Try to log in to infinit.
  [[InfinitStateManager sharedInstance] login:self.loginFormView.login_email_textfield.text
                                     password:self.loginFormView.login_password_textfield.text
                              performSelector:@selector(loginCallback:)
                                     onObject:self];

}

- (void)loginCallback:(InfinitStateResult*)result
{
  
  
  if (result.success)
  {
    [InfinitUserManager sharedInstance];
    [InfinitPeerTransactionManager sharedInstance];
    
    //Add avatar if they have picked a photo.
    if(self.avatar_image)
    {
      [[InfinitStateManager sharedInstance] setSelfAvatar:self.avatar_image performSelector:nil onObject:self];
    }
    
    UIStoryboard* storyboard =
      [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
    UIViewController* viewController =
      [storyboard instantiateViewControllerWithIdentifier:@"tabbarcontroller"];
    [self presentViewController:viewController animated:YES completion:nil];
    
  }
  else
  {
    NSString *resultStatusString = [[NSString alloc] init];
    switch (result.status)
    {
      case gap_email_password_dont_match:
        resultStatusString = NSLocalizedString(@"Login/Password don't match.", @"Login/Password don't match.");
        break;
      case gap_already_logged_in:
        resultStatusString = NSLocalizedString(@"You are already logged in.", @"You are already logged in.");
        break;
      case gap_email_not_confirmed:
        resultStatusString = NSLocalizedString(@"Your email has not been confirmed.", @"Your email has not been confirmed.");
        break;
      case gap_handle_already_registered:
        resultStatusString = NSLocalizedString(@"This handle has already been taken.", @"This handle has already been taken.");
      case gap_meta_down_with_message:
        resultStatusString = NSLocalizedString(@"Our Server is down. Thanks for being patient.", @"Our Server is down. Thanks for being patient.");
        break;
      default:
        resultStatusString = [NSString stringWithFormat:@"%@.",
                 NSLocalizedString(@"Unknown login error", @"unknown login error")];
        break;
    }

    if(self.showingLoginForm)
    {
      self.loginFormView.login_error_label.text = [NSString stringWithFormat:@"Error: %@", resultStatusString];
      self.loginFormView.login_error_label.hidden = NO;
    }
    else
    {
      self.signupFormView.signup_error_label.text = [NSString stringWithFormat:@"Error: %@", resultStatusString];
      self.signupFormView.signup_error_label.hidden = NO;
    }
  }
}

- (void)addParallax
{
  // Set vertical effect
  UIInterpolatingMotionEffect* verticalMotionEffect =
    [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.y"
                                                    type:UIInterpolatingMotionEffectTypeTiltAlongVerticalAxis];
  verticalMotionEffect.minimumRelativeValue = @(-25);
  verticalMotionEffect.maximumRelativeValue = @(25);
  
  // Set horizontal effect
  UIInterpolatingMotionEffect *horizontalMotionEffect =
    [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.x"
                                                    type:UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis];
  horizontalMotionEffect.minimumRelativeValue = @(-25);
  horizontalMotionEffect.maximumRelativeValue = @(25);
  
  // Create group to combine both
  UIMotionEffectGroup* group =
    [UIMotionEffectGroup new];
  group.motionEffects = @[horizontalMotionEffect, verticalMotionEffect];
  
  // Add both effects to your view
  [self.balloonImageView addMotionEffect:group];

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
  
  self.signupFormView.avatar_button.titleEdgeInsets = UIEdgeInsetsMake(0.0,
                                                       0.0,
                                                       0.0,
                                                       0.0);
  self.signupFormView.avatar_button.imageEdgeInsets = UIEdgeInsetsMake(0.0,
                                                       0.0,
                                                       0.0,
                                                       0.0);
  
  [self.signupFormView.avatar_button setTitle:@"" forState:UIControlStateNormal];
  [self.signupFormView.avatar_button setImage:self.avatar_image forState:UIControlStateNormal];
  
  [self.picker dismissViewControllerAnimated:YES completion:nil];
}


-(BOOL)prefersStatusBarHidden
{
  return YES;
}

@end
