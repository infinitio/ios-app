//
//  InfinitWelcomeController.m
//  Infinit
//
//  Created by Michael Dee on 12/14/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import "InfinitWelcomeController.h"

#import <Gap/InfinitUtilities.h>
#import <Gap/InfinitPeerTransactionManager.h>
#import <Gap/InfinitStateManager.h>
#import <Gap/InfinitStateResult.h>
#import <Gap/InfinitUserManager.h>


@interface InfinitWelcomeController () <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UIView* signupFormView;
@property (weak, nonatomic) IBOutlet UIView*loginFormView;
@property (weak, nonatomic) IBOutlet UIButton* avatarButton;
@property (weak, nonatomic) IBOutlet UIButton* loginAvatarButton;

@property (weak, nonatomic) IBOutlet UITextField* signupEmailTextfield;
@property (weak, nonatomic) IBOutlet UITextField* signupFullnameTextfield;
@property (weak, nonatomic) IBOutlet UITextField* signupPasswordTextfield;

@property (weak, nonatomic) IBOutlet UITextField* loginEmailTextfield;
@property (weak, nonatomic) IBOutlet UITextField* loginPasswordTextfield;

@property (weak, nonatomic) IBOutlet UIImageView* signupEmailImageView;
@property (weak, nonatomic) IBOutlet UIImageView* signupProfileImageView;
@property (weak, nonatomic) IBOutlet UIImageView* signupPasswordImageView;

// NEED TO MAKE THIS WORK
@property (weak, nonatomic) IBOutlet UILabel* signupErrorLabel;

@property (weak, nonatomic) IBOutlet UIImageView* loginEmailImageView;
@property (weak, nonatomic) IBOutlet UIImageView* loginPasswordImageView;

@property (weak, nonatomic) IBOutlet UIImageView* logoImageView;
@property (weak, nonatomic) IBOutlet UIImageView* balloonImageView;

@property (weak, nonatomic) IBOutlet UIButton* signUpWithFacebookButton;
@property (weak, nonatomic) IBOutlet UIButton* signupWithEmailButton;
@property (weak, nonatomic) IBOutlet UIButton* loginButton;
@property (weak, nonatomic) IBOutlet UILabel* taglineLabel;

@property (weak, nonatomic) IBOutlet UIButton* loginNextButton;
@property (weak, nonatomic) IBOutlet UIButton* signupNextButton;

@property (weak, nonatomic) IBOutlet UIView* balloonContainerView;


@property BOOL showingLoginForm;

@end

@implementation InfinitWelcomeController

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  [self.view bringSubviewToFront:self.signupFormView];
  [self.view bringSubviewToFront:self.loginFormView];
}

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
   
  
  [self addParallax];
  
  self.signupErrorLabel.text = @"Can we change it";

  self.showingLoginForm = NO;
  
  self.signUpWithFacebookButton.layer.cornerRadius = 5.0;
  self.signupWithEmailButton.layer.cornerRadius = 5.0;
  self.loginButton.layer.cornerRadius = 5.0;
  
  self.signupWithEmailButton.titleLabel.font = [UIFont fontWithName:@"SourceSansPro-Semibold" size:15];
  self.loginButton.titleLabel.font = [UIFont fontWithName:@"SourceSansPro-Semibold" size:15];
  self.signUpWithFacebookButton.titleLabel.font = [UIFont fontWithName:@"SourceSansPro-Semibold" size:15];

  self.taglineLabel.font = [UIFont fontWithName:@"" size:12];

  

  
  self.signupFormView.frame = CGRectMake(0,
                                         self.view.frame.size.height,
                                         self.signupFormView.frame.size.width,
                                         self.signupFormView.frame.size.height);
  
  
  self.loginFormView.frame = CGRectMake(0,
                                        self.view.frame.size.height,
                                        self.loginFormView.frame.size.width,
                                        self.loginFormView.frame.size.height);
  
  
  self.avatarButton.layer.cornerRadius = self.avatarButton.frame.size.width/2;
  self.avatarButton.layer.borderWidth = 1;
  self.avatarButton.layer.borderColor = ([[[UIColor colorWithRed:194/255.0 green:211/255.0 blue:211/255.0 alpha:1] colorWithAlphaComponent:1] CGColor]);
  // the space between the image and text
  CGFloat spacing = 6.0;
  
  // lower the text and push it left so it appears centered
  //  below the image
  CGSize imageSize = self.avatarButton.imageView.image.size;
  self.avatarButton.titleEdgeInsets = UIEdgeInsetsMake(0.0,
                                                       -imageSize.width,
                                                       -(imageSize.height + spacing),
                                                       0.0);
  self.loginAvatarButton.titleEdgeInsets = UIEdgeInsetsMake(0.0,
                                                            -imageSize.width,
                                                            -(imageSize.height + spacing),
                                                            0.0);

  
  // raise the image and push it right so it appears centered
  //  above the text
  CGSize titleSize = [self.avatarButton.titleLabel.text sizeWithAttributes:@{NSFontAttributeName: self.avatarButton.titleLabel.font}];
  self.avatarButton.imageEdgeInsets = UIEdgeInsetsMake(-(titleSize.height + spacing),
                                                       0.0,
                                                       0.0,
                                                       -titleSize.width);
  self.loginAvatarButton.imageEdgeInsets = UIEdgeInsetsMake(-(titleSize.height + spacing),
                                                            0.0,
                                                            0.0, -
                                                            titleSize.width);

  
  self.loginAvatarButton.layer.cornerRadius = self.avatarButton.frame.size.width/2;
  self.loginAvatarButton.layer.borderWidth = 1;
  self.loginAvatarButton.layer.borderColor = ([[[UIColor colorWithRed:194/255.0 green:211/255.0 blue:211/255.0 alpha:1] colorWithAlphaComponent:1] CGColor]);
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(keyboardWillShow:)
                                               name:UIKeyboardWillShowNotification
                                             object:nil];
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(textInputChanged:)
                                               name:UITextFieldTextDidChangeNotification
                                             object:self.signupFullnameTextfield];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(textInputChanged:)
                                               name:UITextFieldTextDidChangeNotification
                                             object:self.signupPasswordTextfield];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(textInputChanged:)
                                               name:UITextFieldTextDidChangeNotification
                                             object:self.signupEmailTextfield];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(textInputChanged:)
                                               name:UITextFieldTextDidChangeNotification
                                             object:self.loginEmailTextfield];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(textInputChanged:)
                                               name:UITextFieldTextDidChangeNotification
                                             object:self.loginPasswordTextfield];
}

-  (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self
                                                  name:UITextFieldTextDidChangeNotification
                                                object:self.signupEmailTextfield];
  [[NSNotificationCenter defaultCenter] removeObserver:self
                                                  name:UITextFieldTextDidChangeNotification
                                                object:self.signupFullnameTextfield];
  [[NSNotificationCenter defaultCenter] removeObserver:self
                                                  name:UITextFieldTextDidChangeNotification
                                                object:self.signupPasswordTextfield];
  [[NSNotificationCenter defaultCenter] removeObserver:self
                                                  name:UITextFieldTextDidChangeNotification
                                                object:self.loginEmailTextfield];
  [[NSNotificationCenter defaultCenter] removeObserver:self
                                                  name:UITextFieldTextDidChangeNotification
                                                object:self.loginPasswordTextfield];
}

- (IBAction)facebookButtonSelected:(id)sender
{
  
}

- (IBAction)signupWithEmailSelected:(id)sender
{
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
                                                            self.view.frame.size.height - 280,
                                                            self.signupFormView.frame.size.width,
                                                            self.signupFormView.frame.size.height);
                     //Move the balloon and background and logo and label as well.  Put them on a view?
                     
                     
                     
                     
  }
  completion:^(BOOL finished)
  {
    NSLog(@"Happy times");
  }];
   
}

- (IBAction)loginButtonSelected:(id)sender
{
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
                                 self.view.frame.size.height - 280,
                                 self.loginFormView.frame.size.width,
                                 self.loginFormView.frame.size.height);
  }
  completion:^(BOOL finished)
  {
    NSLog(@"Happy times");
  }];
}

- (IBAction)signupBackButtonSelected:(id)sender
{
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
    NSLog(@"Happy times");
  }];
}

- (IBAction)loginBackButtonSelected:(id)sender
{
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
                    self.balloonContainerView.frame = CGRectMake(0,0,self.balloonContainerView.frame.size.width,self.balloonContainerView.frame.size.height);
  }
                   completion:nil];
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
                                            20,
                                            self.loginFormView.frame.size.width,
                                            self.loginFormView.frame.size.height);
                      //Also move the background up with it.
                      self.balloonContainerView.frame = CGRectMake(0,-(self.view.frame.size.height - 280),self.balloonContainerView.frame.size.width,self.balloonContainerView.frame.size.height);
      }
                     completion:nil];
    
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
                      20,
                      self.signupFormView.frame.size.width,
                      self.signupFormView.frame.size.height);
                      self.balloonContainerView.frame = CGRectMake(0,-(self.view.frame.size.height - 280),self.balloonContainerView.frame.size.width,self.balloonContainerView.frame.size.height);
    }
                     completion:nil];
  }
}


//- Text Field Delegate ----------------------------------------------------------------------------
- (void)textFieldDidBeginEditing:(UITextField*)textField
{
  if(textField == self.loginEmailTextfield || textField == self.loginPasswordTextfield)
  {
    
  }
}



- (void)textFieldDidEndEditing:(UITextField*)textField
{
  
}

- (BOOL)textFieldShouldReturn:(UITextField*)textField
{
  
  //Logic for moving through text fields.
  if (textField == self.signupEmailTextfield)
  {
    [self.signupFullnameTextfield becomeFirstResponder];
  }
  else if (textField == self.signupFullnameTextfield)
  {
    [self.signupPasswordTextfield becomeFirstResponder];
  }
  else if (textField == self.signupPasswordTextfield)
  {
      [textField resignFirstResponder];
  }
  else if (textField == self.loginEmailTextfield)
  {
    [self.loginPasswordTextfield becomeFirstResponder];
  }
  else if (textField == self.loginPasswordTextfield)
  {
    [textField resignFirstResponder];
  }
  return YES;
}

- (void)textInputChanged:(NSNotification*)note
{
  
//  _signupErrorLabel.text = @"Can we change now";

  
  if(note.object == self.signupPasswordTextfield)
  {
    NSString* password = self.signupPasswordTextfield.text;
    if(password.length < 3)
    {
      
      self.signupPasswordImageView.image = [UIImage imageNamed:@"icon-password-error"];
//      [self.signupErrorLabel setText:@"Your password must be 3 characters min."];
    }
    else
    {
      self.signupPasswordImageView.image = [UIImage imageNamed:@"icon-password-valid"];
    }
  }
  if(note.object == self.signupEmailTextfield)
  {
    NSString* email = self.signupEmailTextfield.text;
    if(![InfinitUtilities stringIsEmail:email])
    {
      self.signupEmailImageView.image = [UIImage imageNamed:@"icon-email-error"];
//      self.signupErrorLabel.text = @"Email Invalid";
    }
    else
    {
      self.signupEmailImageView.image = [UIImage imageNamed:@"icon-email-valid"];
    }
  }
  if(note.object == self.signupFullnameTextfield)
  {
    NSString* fullname = self.signupFullnameTextfield.text;
    if(fullname.length < 3)
    {
      self.signupProfileImageView.image = [UIImage imageNamed:@"icon-fullname-error"];
//      self.signupErrorLabel.text = @"Your name must be 3 characters min.";
    }
    else
    {
      self.signupProfileImageView.image = [UIImage imageNamed:@"icon-fullname-valid"];
    }
  }
  if(note.object == self.loginEmailTextfield)
  {
    NSString* email = self.loginEmailTextfield.text;
    if(![InfinitUtilities stringIsEmail:email])
    {
      self.loginEmailImageView.image = [UIImage imageNamed:@"icon-email-error"];
      //      self.loginErrorLabel.text = @"Email Invalid";
      
    }
    else
    {
      self.loginEmailImageView.image = [UIImage imageNamed:@"icon-email-valid"];
    }
  }
  if(note.object == self.loginPasswordTextfield)
  {
    NSString* password = self.loginPasswordTextfield.text;
    if(password.length < 3)
    {
      
      self.loginPasswordImageView.image = [UIImage imageNamed:@"icon-password-error"];
      //      [self.signupErrorLabel setText:@"Your password must be 3 characters min."];
    }
    else
    {
      self.loginPasswordImageView.image = [UIImage imageNamed:@"icon-password-valid"];
    }
  }
  
  if((self.loginPasswordTextfield.text.length >=3 && [InfinitUtilities stringIsEmail:self.loginEmailTextfield.text]))
  {
    //Show next button
    self.loginNextButton.hidden = NO;
  }
  
  if(self.signupPasswordTextfield.text.length >=3 && self.signupFullnameTextfield.text.length >= 3 && [InfinitUtilities stringIsEmail:self.signupEmailTextfield.text])
  {
    //Show next button
    self.signupNextButton.hidden = NO;
  }
  
  
}

- (IBAction)signupNextButtonSelected:(id)sender
{
  //Start  spinner of some sort?
  
   [[InfinitStateManager sharedInstance] registerFullname:self.signupFullnameTextfield.text
                                                    email:self.signupEmailTextfield.text
                                                 password:self.signupPasswordTextfield.text
                                          performSelector:@selector(loginCallback:)
                                                 onObject:self];
  
}

- (IBAction)loginNextButtonSelected:(id)sender
{
  //Try to log in to infinit.
  [[InfinitStateManager sharedInstance] login:self.loginEmailTextfield.text
                                     password:self.loginPasswordTextfield.text
                              performSelector:@selector(loginCallback:)
                                     onObject:self];

}

- (void)loginCallback:(InfinitStateResult*)result
{
  
  
  if (result.success)
  {
    [InfinitUserManager sharedInstance];
    [InfinitPeerTransactionManager sharedInstance];
    
    UIStoryboard* storyboard =
      [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
    UIViewController* viewController =
      [storyboard instantiateViewControllerWithIdentifier:@"welcomeVC"];
    [self presentViewController:viewController animated:YES completion:nil];
    
  }
  else
  {
//    self.error.text = [NSString stringWithFormat:@"Error: %d", result.status];
  }
}

- (void)addParallax
{
  // Set vertical effect
  UIInterpolatingMotionEffect* verticalMotionEffect =
    [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.y"
                                                    type:UIInterpolatingMotionEffectTypeTiltAlongVerticalAxis];
  verticalMotionEffect.minimumRelativeValue = @(-1);
  verticalMotionEffect.maximumRelativeValue = @(1);
  
  // Set horizontal effect
  UIInterpolatingMotionEffect *horizontalMotionEffect =
    [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.x"
                                                    type:UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis];
  horizontalMotionEffect.minimumRelativeValue = @(-1);
  horizontalMotionEffect.maximumRelativeValue = @(1);
  
  // Create group to combine both
  UIMotionEffectGroup* group =
    [UIMotionEffectGroup new];
  group.motionEffects = @[horizontalMotionEffect, verticalMotionEffect];
  
  // Add both effects to your view
  [self.view addMotionEffect:group];

}

-(BOOL)prefersStatusBarHidden
{
  return YES;
}

@end
