//
//  InfinitHomeRatingCell.m
//  Infinit
//
//  Created by Christopher Crone on 05/02/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitHomeRatingCell.h"

#import "InfinitColor.h"
#import "InfinitHostDevice.h"

@interface InfinitHomeRatingCell ()

@property (nonatomic, weak) IBOutlet UILabel* info_label;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint* negative_width;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint* positive_width;

@end

@implementation InfinitHomeRatingCell

#pragma mark - Init

- (void)awakeFromNib
{
  [super awakeFromNib];
  self.layer.shadowPath = nil;
  self.positive_button.layer.cornerRadius = self.positive_button.bounds.size.height / 2.0f;
  self.negative_button.layer.cornerRadius = self.negative_button.bounds.size.height / 2.0f;
  self.negative_button.layer.borderColor = [InfinitColor colorWithGray:175].CGColor;
  self.negative_button.layer.borderWidth = 1.0f;
  self.state = InfinitRatingCellStateFirst;
  self.positive_button.imageEdgeInsets = UIEdgeInsetsMake(0.0f, -8.0f, 0.0f, 0.0f);
  self.positive_button.titleEdgeInsets = UIEdgeInsetsMake(0.0f, 0.0f, 0.0f, -2.0f);
  self.negative_button.imageEdgeInsets = UIEdgeInsetsMake(4.0f, -8.0f, 0.0f, 0.0f);
  self.negative_button.titleEdgeInsets = UIEdgeInsetsMake(0.0f, 0.0f, 0.0f, -2.0f);
}

- (void)prepareForReuse
{
  self.state = InfinitRatingCellStateFirst;
  [self.positive_button removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
  [self.negative_button removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
}

- (void)setState:(InfinitRatingCellStates)state
{
  if (self.state == state)
    return;
  _state = state;
  switch (state)
  {
    case InfinitRatingCellStateFirst:
      self.info_label.text = NSLocalizedString(@"How's your experience with Infinit?", nil);
      [self.positive_button setTitle:NSLocalizedString(@"GOOD, I LIKE IT!", nil)
                            forState:UIControlStateNormal];
      self.positive_width.constant = 145.0f;
      [self.negative_button setImage:[UIImage imageNamed:@"icon-thumb-down"]
                            forState:UIControlStateNormal];
      [self.negative_button setTitle:NSLocalizedString(@"SO SO", nil)
                            forState:UIControlStateNormal];
      self.negative_width.constant = 91.0f;
      self.negative_button.imageEdgeInsets = UIEdgeInsetsMake(4.0f, -8.0f, 0.0f, 0.0f);
      self.negative_button.titleEdgeInsets = UIEdgeInsetsMake(0.0f, 0.0f, 0.0f, -2.0f);
      break;
    case InfinitRatingCellStateRate:
      self.info_label.text = NSLocalizedString(@"Mind rating us on the App Store?", nil);
      [self.positive_button setTitle:NSLocalizedString(@"SURE!", nil)
                            forState:UIControlStateNormal];
      self.positive_width.constant = 90.0f;
      [self.negative_button setImage:nil forState:UIControlStateNormal];
      [self.negative_button setTitle:NSLocalizedString(@"NO, THANKS", nil)
                            forState:UIControlStateNormal];
      self.negative_width.constant = 108.0f;
      self.negative_button.imageEdgeInsets = UIEdgeInsetsZero;
      self.negative_button.titleEdgeInsets = UIEdgeInsetsZero;
      break;
    case InfinitRatingCellStateFeedback:
      self.info_label.text = NSLocalizedString(@"Do you mind sharing some feedback?", nil);
      [self.positive_button setTitle:NSLocalizedString(@"SURE!", nil)
                            forState:UIControlStateNormal];
      self.positive_width.constant = 90.0f;
      [self.negative_button setImage:nil forState:UIControlStateNormal];
      [self.negative_button setTitle:NSLocalizedString(@"NO, THANKS", nil)
                            forState:UIControlStateNormal];
      self.negative_width.constant = 108.0f;
      self.negative_button.imageEdgeInsets = UIEdgeInsetsZero;
      self.negative_button.titleEdgeInsets = UIEdgeInsetsZero;
      break;


    default:
      break;
  }
}

@end
