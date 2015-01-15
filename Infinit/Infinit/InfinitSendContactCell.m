//
//  InfinitSendContactCell.m
//  Infinit
//
//  Created by Christopher Crone on 12/01/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitSendContactCell.h"

static BOOL _show_numbers = NO;

@implementation InfinitSendContactCell

- (void)awakeFromNib
{
  self.avatar_view.layer.cornerRadius = self.avatar_view.frame.size.width / 2.0f;
  self.avatar_view.clipsToBounds = YES;
}

- (void)prepareForReuse
{
  [super prepareForReuse];
  self.details_label.text = nil;
}

- (void)setContact:(InfinitContact*)contact
{
  [super setContact:contact];
  NSMutableString* res = [[NSMutableString alloc] init];
  if (contact.emails.count > 0)
  {
    [res appendFormat:@"%@", contact.emails[0]];
    if (contact.emails.count > 1)
      [res appendFormat:@"..."];
  }
  if (_show_numbers && contact.phone_numbers.count > 0)
  {
    if (contact.emails.count > 0)
      [res appendFormat:@", "];
    [res appendFormat:@"%@", contact.phone_numbers[0]];
    if (contact.phone_numbers.count > 1)
      [res appendFormat:@"..."];
  }
  self.details_label.text = res;
}

@end
