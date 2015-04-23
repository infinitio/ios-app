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

@property (nonatomic, weak) IBOutlet UILabel* info_label;
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
  self.yes_button.layer.borderWidth = 3.0f;
  self.no_button.layer.cornerRadius = floor(self.no_button.bounds.size.height / 2.0f);
  self.no_button.layer.borderColor = border_color.CGColor;
  self.no_button.layer.borderWidth = 3.0f;
  NSMutableAttributedString* info_text = [self.info_label.attributedText mutableCopy];
  NSMutableParagraphStyle* para = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
  para.alignment = NSTextAlignmentCenter;
  para.lineSpacing = 20.0f;
  [info_text addAttribute:NSParagraphStyleAttributeName
                    value:para 
                    range:NSMakeRange(0, info_text.length)];
  self.info_label.attributedText = info_text;
  self.view.translatesAutoresizingMaskIntoConstraints = NO;
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
