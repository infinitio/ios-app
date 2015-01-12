//
//  InfinitSendUserCell.m
//  Infinit
//
//  Created by Michael Dee on 7/11/14.
//  Copyright (c) 2014 Michael Dee. All rights reserved.
//

#import "InfinitSendUserCell.h"

@implementation InfinitSendUserCell

- (void)awakeFromNib
{
  self.avatar_view.layer.cornerRadius = self.avatar_view.frame.size.width / 2.0f;
  self.avatar_view.clipsToBounds = YES;
  self.user_type_view.layer.cornerRadius = self.user_type_view.frame.size.width / 2.0f;
  self.user_type_view.clipsToBounds = YES;
}

- (void)prepareForReuse
{
  self.user_type_view.image = nil;
}

- (void)setContact:(InfinitContact*)contact
{
  [super setContact:contact];
  if (self.contact.infinit_user.favorite)
    self.user_type_view.image = [UIImage imageNamed:@"icon-contact-favorite"];
  else
    self.user_type_view.image = [UIImage imageNamed:@"icon-contact-infinit"];
}

@end
