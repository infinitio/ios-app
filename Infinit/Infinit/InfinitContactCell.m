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
  __weak InfinitContactCell* weak_self = self;
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^
  {
    UIImage* round_avatar = [contact.avatar infinit_circularMaskOfSize:weak_self.avatar_view.bounds.size];
    dispatch_async(dispatch_get_main_queue(), ^
    {
      weak_self.avatar_view.image = round_avatar;
    });
  });
  self.letter_label.text = [self.contact.fullname substringToIndex:1].uppercaseString;
}

- (void)updateAvatar
{
  __weak InfinitContactCell* weak_self = self;
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^
  {
    InfinitContactUser* contact_user = (InfinitContactUser*)weak_self.contact;
    [contact_user updateAvatar];
    UIImage* round_avatar =
      [weak_self.contact.avatar infinit_circularMaskOfSize:weak_self.avatar_view.bounds.size];
    dispatch_async(dispatch_get_main_queue(), ^
    {
      weak_self.avatar_view.image = round_avatar;
      [weak_self setNeedsDisplay];
    });
  });
}

@end
