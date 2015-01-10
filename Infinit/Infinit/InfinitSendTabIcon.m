//
//  InfinitSendTabIcon.m
//  Infinit
//
//  Created by Christopher Crone on 09/01/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitSendTabIcon.h"

#import "InfinitColor.h"

@implementation InfinitSendTabIcon

- (id)initWithDiameter:(CGFloat)diameter
{
  CGRect frame = CGRectMake(0.0f, 0.0f, diameter, diameter);
  if (self = [super initWithFrame:frame])
  {
    self.backgroundColor = [InfinitColor colorFromPalette:ColorBurntSienna];
    self.layer.cornerRadius = diameter / 2.0f;
    self.clipsToBounds = YES;
    _icon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icon-tab-send"]];
    [self addSubview:self.icon];
    self.icon.center = self.center;
  }
  return self;
}

@end
