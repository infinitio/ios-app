//
//  InfinitContactCell.m
//  Infinit
//
//  Created by Christopher Crone on 31/01/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitContactCell.h"

#import "UIImage+Rounded.h"

static UIImage* _infinit_icon = nil;
static UIImage* _favorite_icon = nil;

@implementation InfinitContactCell

- (void)awakeFromNib
{
  if (_infinit_icon == nil)
    _infinit_icon = [UIImage imageNamed:@"icon-contact-infinit"].circularMask;
  if (_favorite_icon == nil)
    _favorite_icon = [UIImage imageNamed:@"icon-contact-favorite"].circularMask;
}

- (void)setContact:(InfinitContact*)contact
{
  if (contact.infinit_user != nil) // User could've been favorited
  {
    if (contact.infinit_user.favorite)
      self.icon_view.image = _favorite_icon;
    else
      self.icon_view.image = _infinit_icon;
    self.icon_view.hidden = NO;
  }
  if ([self.contact isEqual:contact])
    return;
  _contact = contact;
  self.name_label.text = contact.fullname;
  self.avatar_view.image = contact.avatar.circularMask;
  if (contact.infinit_user == nil)
  {
    self.icon_view.hidden = YES;
  }
}

- (void)updateAvatar
{
  [self.contact updateAvatar];
  self.avatar_view.image = self.contact.avatar.circularMask;
  [self setNeedsDisplay];
}

@end
