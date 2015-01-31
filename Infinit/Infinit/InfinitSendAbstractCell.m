//
//  InfinitSendAbstractCell.m
//  Infinit
//
//  Created by Christopher Crone on 12/01/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitSendAbstractCell.h"

#import "InfinitColor.h"

#import "UIImage+Rounded.h"

@implementation InfinitSendAbstractCell

- (void)prepareForReuse
{
  self.check_view.checked = NO;
}

- (void)setContact:(InfinitContact*)contact
{
  _contact = contact;
  self.avatar_view.image = self.contact.avatar.circularMask;
  if (self.contact.infinit_user != nil && self.contact.infinit_user.is_self)
    self.name_label.text = NSLocalizedString(@"Me (other devices)", nil);
  else
    self.name_label.text = self.contact.fullname;
}

- (void)setSelected:(BOOL)selected
           animated:(BOOL)animated
{
  if (selected)
    self.name_label.textColor = [InfinitColor colorFromPalette:ColorShamRock];
  else
    self.name_label.textColor = [InfinitColor colorWithGray:41];
  [self.check_view setChecked:selected animated:YES];
  [super setSelected:selected animated:animated];
}

@end
