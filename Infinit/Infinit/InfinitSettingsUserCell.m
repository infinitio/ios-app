//
//  InfinitSettingsUserCell.m
//  Infinit
//
//  Created by Christopher Crone on 20/01/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitSettingsUserCell.h"

#import "UIImage+Rounded.h"
#import "UIImage+ImageEffects.h"

@interface InfinitSettingsUserCell ()

@property (nonatomic, weak) IBOutlet UIImageView* background_view;
@property (nonatomic, weak) IBOutlet UIImageView* avatar_view;
@property (nonatomic, weak) IBOutlet UILabel* name_label;

@end

@implementation InfinitSettingsUserCell

- (void)setFrame:(CGRect)frame
{
  CGFloat x_inset = 9.0f;
  frame.origin.x -= x_inset;
  frame.size.width += 2 * x_inset;
  CGFloat y_inset = 2.0f;
  frame.origin.y -= y_inset;
  frame.size.height += y_inset * 2.0f;
  [super setFrame:frame];
}

- (UIEdgeInsets)layoutMargins
{
  return UIEdgeInsetsZero;
}

- (void)configureWithUser:(InfinitUser*)user
{
  self.avatar_view.image = [user.avatar circularMaskOfSize:self.avatar_view.frame.size];
  self.name_label.text = user.fullname;
  self.background_view.image = [user.avatar applyDarkEffect];
  self.clipsToBounds = YES;
}

@end
