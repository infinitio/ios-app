//
//  InfinitAccessContactsView.m
//  Infinit
//
//  Created by Christopher Crone on 12/01/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitAccessContactsView.h"

@implementation InfinitAccessContactsView

- (void)awakeFromNib
{
  self.access_button.layer.cornerRadius = self.access_button.bounds.size.height / 2.0f;
  self.access_button.titleLabel.adjustsFontSizeToFitWidth = YES;
  self.access_button.titleLabel.minimumScaleFactor = 0.5f;
  self.back_button.layer.cornerRadius = self.back_button.bounds.size.height / 2.0f;
  self.back_button.layer.borderColor = [UIColor whiteColor].CGColor;
  self.back_button.layer.borderWidth = 1.0f;
  self.back_button.titleLabel.adjustsFontSizeToFitWidth = YES;
  self.back_button.titleLabel.minimumScaleFactor = 0.5f;
}

@end
