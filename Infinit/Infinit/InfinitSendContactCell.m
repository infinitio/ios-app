//
//  InfinitSendContactCell.m
//  Infinit
//
//  Created by Christopher Crone on 12/01/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitSendContactCell.h"

#import "InfinitHostDevice.h"

#import <Gap/InfinitColor.h>

static BOOL _checked_sms = NO;
static BOOL _show_numbers;

@implementation InfinitSendContactCell

- (void)awakeFromNib
{
  [super awakeFromNib];
  if (!_checked_sms)
  {
    _checked_sms = YES;
    _show_numbers = [InfinitHostDevice canSendSMS];
  }
}

- (void)setContact:(InfinitContact*)contact
{
  if ([self.contact isEqual:contact])
    return;
  [super setContact:contact];
  InfinitContactAddressBook* contact_ab = (InfinitContactAddressBook*)self.contact;
  NSMutableString* res = [[NSMutableString alloc] init];
  if (contact_ab.emails.count > 0)
  {
    [res appendFormat:@"%@", contact_ab.emails[0]];
    if (contact_ab.emails.count > 1 && contact_ab.phone_numbers.count == 0 && _show_numbers)
      [res appendFormat:@"..."];
  }
  if (contact_ab.phone_numbers.count > 0 && _show_numbers)
  {
    if (contact_ab.emails.count > 0)
      [res appendFormat:@", "];
    [res appendFormat:@"%@", contact_ab.phone_numbers[0]];
    if (contact_ab.phone_numbers.count > 1)
      [res appendFormat:@"..."];
  }
  self.details_label.text = res;
  self.letter_label.text = [self.contact.fullname substringToIndex:1].uppercaseString;
}

- (void)setSelected:(BOOL)selected
           animated:(BOOL)animated
{
  if (selected)
    self.details_label.textColor = [InfinitColor colorFromPalette:InfinitPaletteColorShamRock];
  else
    self.details_label.textColor = [InfinitColor colorWithGray:175];
  [super setSelected:selected animated:animated];
}

@end
