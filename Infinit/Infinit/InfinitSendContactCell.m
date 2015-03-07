//
//  InfinitSendContactCell.m
//  Infinit
//
//  Created by Christopher Crone on 12/01/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitSendContactCell.h"

#import "InfinitColor.h"

@implementation InfinitSendContactCell

- (void)setContact:(InfinitContact*)contact
{
  if ([self.contact isEqual:contact])
    return;
  [super setContact:contact];
  NSMutableString* res = [[NSMutableString alloc] init];
  if (contact.emails.count > 0)
  {
    [res appendFormat:@"%@", contact.emails[0]];
    if (contact.emails.count > 1 && contact.phone_numbers.count == 0)
      [res appendFormat:@"..."];
  }
  if (contact.phone_numbers.count > 0)
  {
    if (contact.emails.count > 0)
      [res appendFormat:@", "];
    [res appendFormat:@"%@", contact.phone_numbers[0]];
    if (contact.phone_numbers.count > 1)
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
