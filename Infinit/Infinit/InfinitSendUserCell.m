//
//  InfinitSendUserCell.m
//  Infinit
//
//  Created by Michael Dee on 7/11/14.
//  Copyright (c) 2014 Michael Dee. All rights reserved.
//

#import "InfinitSendUserCell.h"

#import "InfinitColor.h"

#import "UIImage+circular.h"

static NSDictionary* _me_attrs = nil;

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
  if (self.contact.infinit_user.is_self)
    [self setSelfTextColor];
}

- (void)setSelfTextColor
{
  if (_me_attrs == nil)
  {
    _me_attrs = @{NSFontAttributeName: [UIFont fontWithName:@"HelveticaNeue" size:17.0f],
                  NSForegroundColorAttributeName: [InfinitColor colorWithGray:175]};
  }
  NSRange color_range =
    [self.name_label.text rangeOfString:NSLocalizedString(@"(other devices)", nil)];
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
  if (self.contact.infinit_user.is_self && !selected)
    [self setSelfTextColor];
}

- (void)updateAvatar
{
  [self.contact updateAvatar];
  self.avatar_view.image = self.contact.avatar.circularMask;
  [self setNeedsDisplay];
}

@end
