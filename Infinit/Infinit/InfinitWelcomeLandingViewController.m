//
//  InfinitWelcomeLandingViewController.m
//  Infinit
//
//  Created by Christopher Crone on 23/04/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitWelcomeLandingViewController.h"

#import "InfinitColor.h"

@interface InfinitWelcomeLandingViewController ()

@property (nonatomic, weak) IBOutlet UIButton* yes_button;
@property (nonatomic, weak) IBOutlet UIButton* no_button;

@end

@implementation InfinitWelcomeLandingViewController

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

- (void)setTextHidden:(BOOL)hidden
{
  [UIView animateWithDuration:0.2f animations:^
  {
    self.info_label.alpha = hidden ? 0.0f : 1.0f;
  }];
}

#pragma mark - Button Handling

- (IBAction)yesTapped:(id)sender
{
  [self.delegate welcomeLandingHaveAccount:self];
}

- (IBAction)noTapped:(id)sender
{
  [self.delegate welcomeLandingNoAccount:self];
}

@end
