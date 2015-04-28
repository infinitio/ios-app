//
//  InfinitWelcomeOnboardingController.m
//  Infinit
//
//  Created by Christopher Crone on 04/02/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitWelcomeOnboardingController.h"

#import "InfinitHostDevice.h"

@interface InfinitWelcomeOnboardingController ()

@property (nonatomic, weak) IBOutlet UIButton* next_button;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint* bottom_constraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint* image_constraint;

@end

@implementation InfinitWelcomeOnboardingController

- (void)viewDidLoad
{
  [[UIApplication sharedApplication] setStatusBarHidden:YES];
  self.next_button.layer.cornerRadius = self.next_button.bounds.size.height / 2.0f;
  self.next_button.titleEdgeInsets =
    UIEdgeInsetsMake(0.0f,
                     - self.next_button.imageView.frame.size.width,
                     0.0f,
                     self.next_button.imageView.frame.size.width);
  self.next_button.imageEdgeInsets =
    UIEdgeInsetsMake(0.0f,
                     self.next_button.titleLabel.frame.size.width + 10.0f,
                     0.0f,
                     - (self.next_button.titleLabel.frame.size.width + 10.0f));
  if ([InfinitHostDevice smallScreen])
  {
    if (self.bottom_constraint != nil)
      self.bottom_constraint.constant -= 10.0f;
    else
      self.image_constraint.constant -= 10.0f;
    self.image_constraint.constant -= 40.0f;

  }
  [super viewDidLoad];
}

#pragma mark - Button Handling

- (IBAction)doneTapped:(id)sender
{
  [self.delegate welcomeOnboardingDone];
}

#pragma mark - Navigation

- (IBAction)unwind:(UIStoryboardSegue*)unwind_segue
{

}

- (void)prepareForSegue:(UIStoryboardSegue*)segue
                 sender:(id)sender
{
  if ([segue.destinationViewController isKindOfClass:InfinitWelcomeOnboardingController.class])
    ((InfinitWelcomeOnboardingController*)segue.destinationViewController).delegate = self.delegate;
}

@end
