//
//  WelcomeSignupFormView.m
//  Infinit
//
//  Created by Michael Dee on 1/7/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "WelcomeSignupFormView.h"

#import "InfinitColor.h"

@implementation WelcomeSignupFormView

- (void)awakeFromNib
{
  self.avatar_button.layer.cornerRadius = self.avatar_button.frame.size.height / 2.0f;
  self.avatar_button.layer.borderWidth = 1.0f;
  self.avatar_button.layer.borderColor = [InfinitColor colorWithRed:194 green:211 blue:211].CGColor;
  self.avatar_button.clipsToBounds = YES;

  CGFloat spacing = 6.0;
  NSDictionary* attrs = @{NSFontAttributeName: self.avatar_button.titleLabel.font};
  CGSize title_size = [self.avatar_button.titleLabel.text sizeWithAttributes:attrs];
  self.avatar_button.imageEdgeInsets = UIEdgeInsetsMake(-(title_size.height + spacing),
                                                        0.0f,
                                                        0.0f,
                                                        -title_size.width);
  
  CGSize image_size = self.avatar_button.imageView.image.size;
  self.avatar_button.titleEdgeInsets = UIEdgeInsetsMake(0.0f,
                                                        -image_size.width,
                                                        -(image_size.height + spacing),
                                                        0.0f);
  
}

- (CGFloat)height
{
  return 310.0f;
}

- (void)setAvatar:(UIImage*)image
{
  [self.avatar_button setTitle:@"" forState:UIControlStateNormal];
  [self.avatar_button setImage:image forState:UIControlStateNormal];
  self.avatar_button.layer.borderWidth = 0.0f;
}

@end
