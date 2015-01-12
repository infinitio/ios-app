//
//  InfinitImportOverlayView.m
//  Infinit
//
//  Created by Christopher Crone on 12/01/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitImportOverlayView.h"

@implementation InfinitImportOverlayView

- (void)awakeFromNib
{
  self.phone_contacts_button.layer.cornerRadius = 3.0f;
  self.facebook_button.layer.cornerRadius = 3.0f;
  self.facebook_button.imageEdgeInsets = UIEdgeInsetsMake(0.0f, 0.0f, 0.0f, 10.0f);
  self.facebook_button.titleEdgeInsets = UIEdgeInsetsMake(0.0f, 10.0f, 0.0f, 0.0f);
  self.infinit_button.layer.cornerRadius = 3.0f;
  self.infinit_button.imageEdgeInsets = UIEdgeInsetsMake(0.0f, 0.0f, 0.0f, 10.0f);
  self.infinit_button.titleEdgeInsets = UIEdgeInsetsMake(0.0f, 10.0f, 0.0f, 0.0f);
  self.back_button.layer.cornerRadius = 3.0f;
  self.back_button.layer.borderColor = [UIColor whiteColor].CGColor;
  self.back_button.layer.borderWidth = 1.0f;
}

@end
