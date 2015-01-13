//
//  InfinitSendAbstractCell.m
//  Infinit
//
//  Created by Christopher Crone on 12/01/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitSendAbstractCell.h"

#import "InfinitColor.h"

@implementation InfinitSendAbstractCell

- (void)prepareForReuse
{
  self.check_view.checked = NO;
  self.avatar_view.image = nil;
  self.name_label.text = nil;
}

- (void)setContact:(InfinitContact*)contact
{
  _contact = contact;
  self.avatar_view.image = contact.avatar;
  self.name_label.text = contact.fullname;
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
