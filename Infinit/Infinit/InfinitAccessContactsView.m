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
  self.access_button.layer.cornerRadius = 3.0f;
  self.back_button.layer.cornerRadius = 3.0f;
  self.back_button.layer.borderColor = [UIColor whiteColor].CGColor;
  self.back_button.layer.borderWidth = 1.0f;
}

@end