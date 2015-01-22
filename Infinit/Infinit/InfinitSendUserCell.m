//
//  InfinitSendUserCell.m
//  Infinit
//
//  Created by Michael Dee on 7/11/14.
//  Copyright (c) 2014 Michael Dee. All rights reserved.
//

#import "InfinitSendUserCell.h"

#import "UIImage+circular.h"

@implementation InfinitSendUserCell

- (void)setContact:(InfinitContact*)contact
{
  if ([self.contact isEqual:contact])
    return;
  [super setContact:contact];
  if (self.contact.infinit_user.favorite || self.contact.infinit_user.is_self)
    self.user_type_view.image = [UIImage imageNamed:@"icon-contact-favorite"].circularMask;
  else
    self.user_type_view.image = [UIImage imageNamed:@"icon-contact-infinit"].circularMask;
}

- (void)updateAvatar
{
  [self.contact updateAvatar];
  self.avatar_view.image = self.contact.avatar.circularMask;
  [self setNeedsDisplay];
}

@end
