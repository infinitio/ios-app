//
//  InfinitSendNoResultsCell.m
//  Infinit
//
//  Created by Christopher Crone on 20/01/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitSendNoResultsCell.h"

#import "InfinitColor.h"

@implementation InfinitSendNoResultsCell

- (void)awakeFromNib
{
  [self setupButton:self.contacts_button];
  self.facebook_button.hidden = YES;
  self.facebook_button.enabled = NO;
  [self setupButton:self.facebook_button];
}

- (void)setShow_buttons:(BOOL)show_buttons
{
  self.contacts_button.hidden = !show_buttons;
//  self.facebook_button.hidden = !show_buttons;
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
