//
//  InfinitContactCell.m
//  Infinit
//
//  Created by Christopher Crone on 31/01/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitContactCell.h"

#import "UIImage+Rounded.h"

static UIImage* _favorite_icon = nil;
static UIImage* _me_icon = nil;

@implementation InfinitContactCell

- (void)awakeFromNib
{
  if (_favorite_icon == nil)
    _favorite_icon = [UIImage imageNamed:@"icon-contact-favorite"];
  if (_me_icon == nil)
    _me_icon = [UIImage imageNamed:@"icon-device-mac"];
  self.letter_label.hidden = YES;
  self.icon_view.hidden = YES;
}

- (void)setContact:(InfinitContact*)contact
{
  if ([contact isKindOfClass:InfinitContactUser.class])
  {
    InfinitContactUser* contact_user = (InfinitContactUser*)contact;
    if (contact_user.infinit_user.is_self)
      self.icon_view.image = _me_icon;
    else if (contact_user.infinit_user.favorite)
      self.icon_view.image = _favorite_icon;
  }
  if ([self.contact isEqual:contact])
    return;
  _contact = contact;
  self.name_label.text = contact.fullname;
  self.avatar_view.image = [contact.avatar infinit_circularMaskOfSize:self.avatar_view.bounds.size];
  self.letter_label.text = [self.contact.fullname substringToIndex:1].uppercaseString;
}

- (void)updateAvatar
{
  InfinitContactUser* contact_user = (InfinitContactUser*)self.contact;
  [contact_user updateAvatar];
  self.avatar_view.image =
    [self.contact.avatar infinit_circularMaskOfSize:self.avatar_view.bounds.size];
  [self setNeedsDisplay];
}

@end
