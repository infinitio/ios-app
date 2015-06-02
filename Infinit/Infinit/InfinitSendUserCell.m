//
//  InfinitSendUserCell.m
//  Infinit
//
//  Created by Michael Dee on 7/11/14.
//  Copyright (c) 2014 Michael Dee. All rights reserved.
//

#import "InfinitSendUserCell.h"

#import "InfinitColor.h"

#import "UIImage+Rounded.h"

static NSDictionary* _me_attrs = nil;
static UIImage* _mac_image = nil;
static UIImage* _star_image = nil;

@implementation InfinitSendUserCell

- (void)setContact:(InfinitContact*)contact
{
  if ([self.contact isEqual:contact])
    return;
  super.contact = contact;
  InfinitContactUser* contact_user = (InfinitContactUser*)self.contact;
  if (contact_user.infinit_user.is_self)
  {
    if (_mac_image == nil)
      _mac_image = [UIImage imageNamed:@"icon-device-mac"];
    self.user_type_view.image = _mac_image;
    [self setSelfTextColor];
  }
  else
  {
    if (_star_image == nil)
      _star_image = [UIImage imageNamed:@"icon-contact-favorite"];
    self.user_type_view.image = _star_image;
  }
}

- (void)setSelfTextColor
{
  if (_me_attrs == nil)
  {
    _me_attrs = @{NSFontAttributeName: [UIFont fontWithName:@"HelveticaNeue" size:17.0f],
                  NSForegroundColorAttributeName: [InfinitColor colorWithGray:175]};
  }
  NSRange color_range =
    [self.name_label.text rangeOfString:NSLocalizedString(@"(my other devices)", nil)];
  if (color_range.location != NSNotFound)
  {
    NSMutableAttributedString* res = [self.name_label.attributedText mutableCopy];
    [res setAttributes:_me_attrs range:color_range];
    self.name_label.attributedText = res;
  }
}

- (void)setSelected:(BOOL)selected
           animated:(BOOL)animated
{
  [super setSelected:selected animated:animated];
  InfinitContactUser* contact_user = (InfinitContactUser*)self.contact;
  if (contact_user.infinit_user.is_self && !selected)
    [self setSelfTextColor];
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
