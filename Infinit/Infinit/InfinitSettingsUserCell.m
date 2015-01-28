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

@implementation InfinitSettingsUserCell

- (void)setFrame:(CGRect)frame
{
  CGFloat inset = 9.0f;
  frame.origin.x -= inset;
  frame.size.width += 2 * inset;
  [super setFrame:frame];
}

- (void)configureWithUser:(InfinitUser*)user
{
  self.avatar_view.image = user.avatar.circularMask;
  self.name_label.text = user.fullname;
  self.background_view.image = [user.avatar applyDarkEffect];
  self.clipsToBounds = YES;
}

@end
