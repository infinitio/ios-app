//
//  InfinitWelcomeController.m
//  Infinit
//
//  Created by Michael Dee on 12/14/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import "InfinitWelcomeController.h"

@interface InfinitWelcomeController ()

@property (weak, nonatomic) IBOutlet UIView* signupFormView;
@property (weak, nonatomic) IBOutlet UIView *loginFormView;
@property (weak, nonatomic) IBOutlet UIButton* avatarButton;

@property (weak, nonatomic) IBOutlet UITextField *signupEmailTextfield;
@property (weak, nonatomic) IBOutlet UITextField *signupFullnameTextfield;
@property (weak, nonatomic) IBOutlet UITextField *signupPasswordTextfield;

@property (weak, nonatomic) IBOutlet UITextField *loginEmailTextfield;
@property (weak, nonatomic) IBOutlet UITextField *loginPasswordTextfield;

@end

@implementation InfinitWelcomeController

- (void)viewDidLoad
{
  [super viewDidLoad];
  
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
  self.avatarButton.layer.borderColor = ([[[UIColor blackColor] colorWithAlphaComponent:1] CGColor]);
  self.avatarButton.backgroundColor = [UIColor redColor];
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(keyboardWasShown:)
                                               name:UIKeyboardDidShowNotification
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(keyboardWillHide)
                                               name:UIKeyboardWillHideNotification
                                             object:nil];
  
}

- (IBAction)facebookButtonSelected:(id)sender
{
  
}

- (IBAction)signupWithEmailSelected:(id)sender
{
  [UIView animateWithDuration:1 delay:.1 usingSpringWithDamping:1 initialSpringVelocity:2 options:UIViewAnimationOptionCurveEaseIn animations:^{
    self.signupFormView.frame = CGRectMake(0,
                                           self.view.frame.size.height - self.signupFormView.frame.size.height,
                                           self.signupFormView.frame.size.width,
                                           self.signupFormView.frame.size.height);
  }completion:^(BOOL finished) {
    NSLog(@"Happy times");
  }];
}

- (IBAction)loginButtonSelected:(id)sender
{
  CGRect viewFrame = self.view.frame;
  CGRect formFrame = self.loginFormView.frame;
  CGFloat newOrigin = viewFrame.size.height - formFrame.size.height;
  NSLog(@"%f",newOrigin);


  [UIView animateWithDuration:1 delay:.1 usingSpringWithDamping:1 initialSpringVelocity:2 options:UIViewAnimationOptionCurveEaseIn animations:^{
    self.loginFormView.frame = CGRectMake(0,
                                           self.view.frame.size.height - self.loginFormView.frame.size.height,
                                           self.loginFormView.frame.size.width,
                                           self.loginFormView.frame.size.height);
  }completion:^(BOOL finished) {
    
    CGRect frame = self.loginFormView.frame;
    NSLog(@"Happy times");
  }];
  
}

- (IBAction)signupBackButtonSelected:(id)sender
{
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

//- Text Field Delegate ----------------------------------------------------------------------------

- (BOOL)textFieldShouldReturn:(UITextField*)textField
{
  if (textField == self.signupEmailTextfield)
  {
  }
  else if (textField == self.signupFullnameTextfield)
  {
  } else if (textField == self.signupPasswordTextfield)
  {
    //Login Now.
  }
  return YES;
}



- (void)keyboardWasShown:(NSNotification *)notification
{
  
  // Get the size of the keyboard.
  CGSize keyboardSize = [[[notification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
  
  //Given size may not account for screen rotation
  int height = MIN(keyboardSize.height,keyboardSize.width);
  int width = MAX(keyboardSize.height,keyboardSize.width);
  
  //your other code here..........
  
  
}

- (void)keyboardWillHide
{
  
}


- (void)textFieldDidBeginEditing:(UITextField*)textField
{
}

- (void)textFieldDidEndEditing:(UITextField*)textField
{
}


@end
