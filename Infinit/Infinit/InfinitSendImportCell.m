//
//  InfinitSendImportCell.m
//  Infinit
//
//  Created by Michael Dee on 12/23/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import "InfinitSendImportCell.h"

#import "InfinitColor.h"

static NSAttributedString* bold_str = nil;

@implementation InfinitSendImportCell

- (void)awakeFromNib
{
  [self setMessageLabelBold];
  self.phone_contacts_button.layer.borderColor = [InfinitColor colorWithGray:137].CGColor;
  self.phone_contacts_button.layer.borderWidth = 1.0f;
  self.phone_contacts_button.layer.cornerRadius = 3.0f;

  self.facebook_button.layer.borderColor = [InfinitColor colorWithRed:42 green:108 blue:181].CGColor;
  self.facebook_button.layer.borderWidth = 1.0f;
  self.facebook_button.layer.cornerRadius = 3.0f;

  self.infinit_button.layer.borderColor = [InfinitColor colorFromPalette:ColorBurntSienna].CGColor;
  self.infinit_button.layer.borderWidth = 1.0f;
  self.infinit_button.layer.cornerRadius = 3.0f;
}

- (void)setMessageLabelBold
{
  NSMutableAttributedString* temp =
    [[NSMutableAttributedString alloc] initWithAttributedString:self.message_label.attributedText];
  NSRange range_2x = [temp.string rangeOfString:NSLocalizedString(@"2x faster", nil)];
  NSRange range_enc = [temp.string rangeOfString:NSLocalizedString(@"encrypted", nil)];
  UIFont* bold_font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:17.0f];
  [temp removeAttribute:NSFontAttributeName range:range_2x];
  [temp addAttribute:NSFontAttributeName value:bold_font range:range_2x];
  [temp removeAttribute:NSFontAttributeName range:range_enc];
  [temp addAttribute:NSFontAttributeName value:bold_font range:range_enc];
  bold_str = [[NSAttributedString alloc] initWithAttributedString:temp];
  self.message_label.attributedText = temp;
}

@end
