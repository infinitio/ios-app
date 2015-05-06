//
//  InfinitContactImportCell.m
//  Infinit
//
//  Created by Michael Dee on 12/23/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import "InfinitContactImportCell.h"

#import <Gap/InfinitColor.h>

static NSAttributedString* bold_str = nil;

@implementation InfinitContactImportCell

- (void)awakeFromNib
{
  [self setMessageLabelBold];
  [self setupButton:self.phone_contacts_button];

  self.facebook_button.hidden = YES;
  self.facebook_button.enabled = NO;

  [self setupButton:self.facebook_button];
  self.phone_contacts_button.titleLabel.adjustsFontSizeToFitWidth = YES;
  self.phone_contacts_button.titleLabel.minimumScaleFactor = 0.5f;
}

- (void)prepareForReuse
{
  [self.phone_contacts_button removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
  [self.facebook_button removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
}

- (void)setMessageLabelBold
{
  NSMutableAttributedString* temp =
    [[NSMutableAttributedString alloc] initWithAttributedString:self.message_label.attributedText];
  NSRange range_2x = [temp.string rangeOfString:NSLocalizedString(@"30x faster", nil)];
  UIFont* bold_font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:17.0f];
  [temp removeAttribute:NSFontAttributeName range:range_2x];
  [temp addAttribute:NSFontAttributeName value:bold_font range:range_2x];
  bold_str = [[NSAttributedString alloc] initWithAttributedString:temp];
  self.message_label.attributedText = temp;
}

- (void)setupButton:(UIButton*)button
{
  button.layer.masksToBounds = NO;
  button.layer.shadowOpacity = 0.75f;
  button.layer.shadowColor = [InfinitColor colorWithGray:0 alpha:0.3f].CGColor;
  button.layer.shadowOffset = CGSizeMake(0.0f, 0.0f);
  button.layer.shadowRadius = 1.5f;
  button.layer.cornerRadius = button.bounds.size.height / 2.0f;
}

@end
