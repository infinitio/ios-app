//
//  InfinitWelcomeOnboardingController.m
//  Infinit
//
//  Created by Christopher Crone on 04/02/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitWelcomeOnboardingController.h"

@interface InfinitWelcomeOnboardingController ()

@property (nonatomic, weak) IBOutlet UIButton* next_button;
@property (nonatomic, weak) IBOutlet UILabel* title_label;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint* center_image_constraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint* h_get_started_constraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint* w_get_started_constraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint* bottom_constraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint* top_constraint;

@end

@implementation InfinitWelcomeOnboardingController

- (void)viewDidLoad
{
  [super viewDidLoad];
  [[UIApplication sharedApplication] setStatusBarHidden:YES];
  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
  {
    self.center_image_constraint.constant = -30.0f;
    self.next_button.layer.cornerRadius = floor(self.next_button.bounds.size.height / 2.0f);
  }
  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
  {
    if (self.h_get_started_constraint && self.w_get_started_constraint)
    {
      self.next_button.imageEdgeInsets = UIEdgeInsetsMake(2.0f, 150.0f, 0.0f, 0.0f);
      self.next_button.titleEdgeInsets = UIEdgeInsetsMake(0.0f, -25.0f, 0.0f, 0.0f);
      self.h_get_started_constraint.constant = 60.0f;
      self.next_button.layer.cornerRadius = 30.0f;
      self.w_get_started_constraint.constant = 180.0f;
      NSMutableAttributedString* title = [self.next_button.titleLabel.attributedText mutableCopy];
      [title setAttributes:@{NSFontAttributeName: [UIFont fontWithName:@"SourceSansPro-Bold"
                                                                  size:20.0f]}
                     range:NSMakeRange(0, title.mutableString.length)];
      [self.next_button setAttributedTitle:title forState:UIControlStateNormal];
    }
    self.bottom_constraint.constant += 20.0f;
    self.top_constraint.constant += 35.0f;
    self.center_image_constraint.constant = -50.0f;
    NSDictionary* attrs = [self.title_label.attributedText attributesAtIndex:0 effectiveRange:NULL];
    NSString* title = [self.title_label.text stringByReplacingOccurrencesOfString:@"\n"
                                                                       withString:@" "];
    self.title_label.numberOfLines = 1;
    self.title_label.attributedText = [[NSAttributedString alloc] initWithString:title
                                                                      attributes:attrs];
  }
}

- (void)viewWillAppear:(BOOL)animated
{
  UIDeviceOrientation orientation =
  [[[UIDevice currentDevice] valueForKey:@"orientation"] integerValue];
  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone &&
      orientation != UIDeviceOrientationPortrait)
  {
    [super viewWillAppear:NO];
    [UIView setAnimationsEnabled:NO];
    [[UIDevice currentDevice] setValue:[NSNumber numberWithInt:UIDeviceOrientationPortrait]
                                forKey:@"orientation"];
  }
  else
  {
    [super viewWillAppear:animated];
  }
}

- (void)viewDidAppear:(BOOL)animated
{
  UIDeviceOrientation orientation =
  [[[UIDevice currentDevice] valueForKey:@"orientation"] integerValue];
  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone &&
      orientation != UIDeviceOrientationPortrait)
  {
    [super viewDidAppear:NO];
  }
  else
  {
    [super viewDidAppear:animated];
  }
  [UIView setAnimationsEnabled:YES];
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
