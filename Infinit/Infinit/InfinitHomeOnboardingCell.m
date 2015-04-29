//
//  InfinitHomeOnboardingCell.m
//  Infinit
//
//  Created by Christopher Crone on 20/01/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitHomeOnboardingCell.h"

#import "InfinitHostDevice.h"

#import <Gap/InfinitColor.h>

@interface InfinitHomeOnboardingCell ()

@property (nonatomic, weak) IBOutlet UIImageView* icon_view;
@property (nonatomic, weak) IBOutlet UILabel* message_label;

@end

static NSDictionary* _attrs = nil;
static NSDictionary* _gray_attrs = nil;

@implementation InfinitHomeOnboardingCell

- (void)awakeFromNib
{
  [super awakeFromNib];
  self.layer.shadowPath = nil;
  self.translatesAutoresizingMaskIntoConstraints = NO;
  if (_attrs == nil)
  {
    NSMutableParagraphStyle* para = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    para.lineSpacing = 7.0f;
    _attrs = @{NSFontAttributeName: [UIFont fontWithName:@"HelveticaNeue" size:14.0f],
               NSForegroundColorAttributeName: [InfinitColor colorWithRed:81 green:81 blue:73],
               NSParagraphStyleAttributeName: para};
  }
  if (_gray_attrs == nil)
  {
    NSMutableParagraphStyle* para = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    para.lineSpacing = 7.0f;
    _gray_attrs = @{NSFontAttributeName: [UIFont fontWithName:@"HelveticaNeue" size:14.0f],
                    NSForegroundColorAttributeName: [InfinitColor colorWithGray:158],
                    NSParagraphStyleAttributeName: para};
  }
}

- (void)setType:(InfinitHomeOnboardingCellType)type
       withText:(NSString*)text
      grayRange:(NSRange)gray_range
  numberOfLines:(NSInteger)lines
{
  _type = type;
  NSMutableAttributedString* res = [[NSMutableAttributedString alloc] initWithString:text 
                                                                          attributes:_attrs];
  if (gray_range.location != NSNotFound)
    [res setAttributes:_gray_attrs range:gray_range];
  self.message_label.attributedText = res;
  self.message_label.numberOfLines = lines;
  self.icon_view.image = [self imageForType:type];
}

- (UIImage*)imageForType:(InfinitHomeOnboardingCellType)type
{
  NSString* image_name = nil;
  switch (type)
  {
    case InfinitHomeOnboardingCellSwipe:
      image_name = @"icon-onboarding-swipe";
      break;
    case InfinitHomeOnboardingCellNotifications:
      image_name = @"icon-onboarding-feed";
      break;
    case InfinitHomeOnboardingCellBackground:
      image_name = @"icon-onboarding-background";
      break;
    case InfinitHomeOnboardingCellSelfSent:
      image_name = @"icon-onboarding-self";
      break;
    case InfinitHomeOnboardingCellPeerSent:
    case InfinitHomeOnboardingCellGhostSent:
      image_name = @"icon-onboarding-sent";
      break;

    default:
      break;
  }
  if (image_name == nil)
    return nil;
  return [UIImage imageNamed:image_name];
}

@end
