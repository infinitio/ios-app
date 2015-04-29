//
//  InfinitWelcomeInvitedViewController.m
//  Infinit
//
//  Created by Christopher Crone on 23/04/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitWelcomeInvitedViewController.h"

#import "InfinitColor.h"

@interface InfinitWelcomeInvitedViewController ()

@property (nonatomic, weak) IBOutlet UIActivityIndicatorView* activity;
@property (nonatomic, weak) IBOutlet UIButton* yes_button;
@property (nonatomic, weak) IBOutlet UIButton* no_button;

@end

@implementation InfinitWelcomeInvitedViewController

- (void)resetView
{
  [super resetView];
  self.yes_button.hidden = NO;
  self.no_button.hidden = NO;
  [self.activity stopAnimating];
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  UIColor* border_color = [InfinitColor colorWithRed:91 green:99 blue:106];
  self.yes_button.layer.cornerRadius = floor(self.yes_button.bounds.size.height / 2.0f);
  self.yes_button.layer.borderColor = border_color.CGColor;
  self.yes_button.layer.borderWidth = 2.0f;
  self.no_button.layer.cornerRadius = floor(self.no_button.bounds.size.height / 2.0f);
  self.no_button.layer.borderColor = border_color.CGColor;
  self.no_button.layer.borderWidth = 2.0f;
}

- (void)facebookRegister
{
  self.yes_button.hidden = YES;
  self.no_button.hidden = YES;
  [self.activity startAnimating];
}

#pragma mark - Button Handling

- (IBAction)yesTapped:(id)sender
{
  [self.delegate welcomeInvited:self];
}

- (IBAction)noTapped:(id)sender
{
  [self.delegate welcomeNotInvited:self];
}

@end
