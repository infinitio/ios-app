//
//  InfinitWelcomeController.m
//  Infinit
//
//  Created by Michael Dee on 12/14/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import "InfinitWelcomeController.h"

@interface InfinitWelcomeController ()

@property (weak, nonatomic) IBOutlet UIView *signupFormView;
@property (weak, nonatomic) IBOutlet UIButton *avatarButton;

@end

@implementation InfinitWelcomeController

- (void)viewDidLoad
{
  [super viewDidLoad];

  //Set frames for the signup and login views.
  self.signupFormView.frame = CGRectMake(self.view.frame.size.width, self.view.frame.size.height, self.signupFormView.frame.size.height, self.signupFormView.frame.size.height);
  
  self.signupFormView.backgroundColor = [UIColor whiteColor];
  self.avatarButton.layer.cornerRadius = 31;
  self.avatarButton.layer.borderWidth = 2;
  self.avatarButton.layer.borderColor = (__bridge CGColorRef)([UIColor blackColor]);
}

- (IBAction)facebookButtonSelected:(id)sender
{
  
}

- (IBAction)signupWithEmailSelected:(id)sender
{
  
}

- (IBAction)loginButtonSelected:(id)sender
{
  
  
}



@end
