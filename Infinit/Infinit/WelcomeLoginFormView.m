//
//  WelcomeLoginFormView.m
//  Infinit
//
//  Created by Michael Dee on 1/7/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "WelcomeLoginFormView.h"

@implementation WelcomeLoginFormView

- (void)awakeFromNib
{
  self.avatar_button.layer.cornerRadius = self.avatar_button.frame.size.height / 2.0f;
  self.avatar_button.clipsToBounds = YES;
}

- (CGFloat)height
{
  return 310.0f;
}

@end