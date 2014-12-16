//
//  InfinitWelcomeController.m
//  Infinit
//
//  Created by Michael Dee on 12/14/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import "InfinitWelcomeController.h"
#import <Gap/InfinitUtilities.h>


@interface InfinitWelcomeController () <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UIView* signupFormView;
@property (weak, nonatomic) IBOutlet UIView *loginFormView;
@property (weak, nonatomic) IBOutlet UIButton* avatarButton;
@property (weak, nonatomic) IBOutlet UIButton *loginAvatarButton;

@property (weak, nonatomic) IBOutlet UITextField *signupEmailTextfield;
@property (weak, nonatomic) IBOutlet UITextField *signupFullnameTextfield;
@property (weak, nonatomic) IBOutlet UITextField *signupPasswordTextfield;

@property (weak, nonatomic) IBOutlet UITextField *loginEmailTextfield;
@property (weak, nonatomic) IBOutlet UITextField *loginPasswordTextfield;

@property (weak, nonatomic) IBOutlet UIImageView *signupEmailImageView;
@property (weak, nonatomic) IBOutlet UIImageView *signupProfileImageView;
@property (weak, nonatomic) IBOutlet UIImageView *signupPasswordImageView;

@property (weak, nonatomic) IBOutlet UILabel *signupErrorLabel;

@property (weak, nonatomic) IBOutlet UIImageView *loginEmailImageView;
@property (weak, nonatomic) IBOutlet UIImageView *loginPasswordImageView;

@property (weak, nonatomic) IBOutlet UIImageView *logoImageView;
@property (weak, nonatomic) IBOutlet UIImageView *balloonImageView;


@property BOOL showingLoginForm;


@end

@implementation InfinitWelcomeController

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  [self addParallax];
  
  self.signupErrorLabel.text = @"Can we change it";

  self.showingLoginForm = NO;
  
  self.signupFormView.frame = CGRectMake(0,
                                         self.view.frame.size.height,
                                         self.signupFormView.frame.size.width,
                                         self.signupFormView.frame.size.height);
  
  [self.view bringSubviewToFront:self.signupFormView];
  
  self.loginFormView.frame = CGRectMake(0,
                                        self.view.frame.size.height,
                                        self.loginFormView.frame.size.width,
                                        self.loginFormView.frame.size.height);
  
  [self.view bringSubviewToFront:self.loginFormView];
  
  self.avatarButton.layer.cornerRadius = self.avatarButton.frame.size.width/2;
  self.avatarButton.layer.borderWidth = 2;
  self.avatarButton.layer.borderColor = ([[[UIColor colorWithRed:181/255.0 green:181/255.0 blue:181/255.0 alpha:1] colorWithAlphaComponent:1] CGColor]);
  
  self.loginAvatarButton.layer.cornerRadius = self.avatarButton.frame.size.width/2;
  self.loginAvatarButton.layer.borderWidth = 2;
  self.loginAvatarButton.layer.borderColor = ([[[UIColor colorWithRed:181/255.0 green:181/255.0 blue:181/255.0 alpha:1] colorWithAlphaComponent:1] CGColor]);
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(keyboardWillShow:)
                                               name:UIKeyboardWillShowNotification
                                             object:nil];
  
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textInputChanged:) name:UITextFieldTextDidChangeNotification object:self.signupFullnameTextfield];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textInputChanged:) name:UITextFieldTextDidChangeNotification object:self.signupPasswordTextfield];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textInputChanged:) name:UITextFieldTextDidChangeNotification object:self.signupEmailTextfield];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textInputChanged:) name:UITextFieldTextDidChangeNotification object:self.loginEmailTextfield];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textInputChanged:) name:UITextFieldTextDidChangeNotification object:self.loginPasswordTextfield];
  
}

-  (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self name:UITextFieldTextDidChangeNotification object:self.signupEmailTextfield];
  [[NSNotificationCenter defaultCenter] removeObserver:self name:UITextFieldTextDidChangeNotification object:self.signupFullnameTextfield];
  [[NSNotificationCenter defaultCenter] removeObserver:self name:UITextFieldTextDidChangeNotification object:self.signupPasswordTextfield];
  [[NSNotificationCenter defaultCenter] removeObserver:self name:UITextFieldTextDidChangeNotification object:self.loginEmailTextfield];
  [[NSNotificationCenter defaultCenter] removeObserver:self name:UITextFieldTextDidChangeNotification object:self.loginPasswordTextfield];
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

  [UIView animateWithDuration:1 delay:.1 usingSpringWithDamping:1 initialSpringVelocity:2 options:UIViewAnimationOptionCurveEaseIn animations:^{
    self.signupFormView.frame = CGRectMake(0,
                                           self.view.frame.size.height - 280,
                                           self.signupFormView.frame.size.width,
                                           self.signupFormView.frame.size.height);
  }completion:^(BOOL finished) {
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

  [UIView animateWithDuration:1 delay:.1 usingSpringWithDamping:1 initialSpringVelocity:2 options:UIViewAnimationOptionCurveEaseIn animations:^{
    self.loginFormView.frame = CGRectMake(0,
                                           self.view.frame.size.height - 280,
                                           self.loginFormView.frame.size.width,
                                           self.loginFormView.frame.size.height);
  }completion:^(BOOL finished) {
    
    CGRect frame = self.loginFormView.frame;
    NSLog(@"Happy times");
  }];
  
}

- (IBAction)signupBackButtonSelected:(id)sender
{
  [self.view endEditing:YES];
  [UIView animateWithDuration:1 delay:.1 usingSpringWithDamping:1 initialSpringVelocity:2 options:UIViewAnimationOptionCurveEaseIn animations:^{
    self.signupFormView.frame = CGRectMake(0,
                                           self.view.frame.size.height,
                                           self.signupFormView.frame.size.width,
                                           self.signupFormView.frame.size.height);
  }completion:^(BOOL finished) {
    NSLog(@"Happy times");
  }];
}

- (IBAction)loginBackButtonSelected:(id)sender
{
  [self.view endEditing:YES];
  [UIView animateWithDuration:1 delay:.1 usingSpringWithDamping:1 initialSpringVelocity:2 options:UIViewAnimationOptionCurveEaseIn animations:^{
    self.loginFormView.frame = CGRectMake(0,
                                           self.view.frame.size.height,
                                           self.loginFormView.frame.size.width,
                                           self.loginFormView.frame.size.height);
  }completion:^(BOOL finished) {
    NSLog(@"Happy times");
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
    [UIView animateWithDuration:1
                          delay:.1
         usingSpringWithDamping:1
          initialSpringVelocity:2
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                       self.loginFormView.frame = CGRectMake(0,
                                            20,
                                            self.loginFormView.frame.size.width,
                                            self.loginFormView.frame.size.height);
    }completion:^(BOOL finished) {
      CGRect frame = self.loginFormView.frame;
      NSLog(@"Happy times");
    }];
    
  } else
  {
    //Move the signup form up.
    [UIView animateWithDuration:1
                          delay:.1
         usingSpringWithDamping:1
          initialSpringVelocity:2
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^
                    {
                      self.signupFormView.frame = CGRectMake(0,
                      20,
                      self.signupFormView.frame.size.width,
                      self.signupFormView.frame.size.height);
                    }
                     completion:^(BOOL finished)
    {
      NSLog(@"Happy times");
    }];
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
    } else {
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
    } else {
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
    } else {
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
    } else {
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
    } else {
      self.loginPasswordImageView.image = [UIImage imageNamed:@"icon-password-valid"];
    }
  }
}

- (void)addParallax
{
  // Set vertical effect
  UIInterpolatingMotionEffect* verticalMotionEffect =
  [[UIInterpolatingMotionEffect alloc]
   initWithKeyPath:@"center.y"
   type:UIInterpolatingMotionEffectTypeTiltAlongVerticalAxis];
  verticalMotionEffect.minimumRelativeValue = @(-1);
  verticalMotionEffect.maximumRelativeValue = @(1);
  
  // Set horizontal effect
  UIInterpolatingMotionEffect *horizontalMotionEffect =
  [[UIInterpolatingMotionEffect alloc]
   initWithKeyPath:@"center.x"
   type:UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis];
  horizontalMotionEffect.minimumRelativeValue = @(-1);
  horizontalMotionEffect.maximumRelativeValue = @(1);
  
  // Create group to combine both
  UIMotionEffectGroup *group = [UIMotionEffectGroup new];
  group.motionEffects = @[horizontalMotionEffect, verticalMotionEffect];
  
  // Add both effects to your view
  [self.view addMotionEffect:group];

}


@end
