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

- (id)initWithFrame:(CGRect)frame
{
  if (self = [super initWithFrame:frame])
  {
    self.image = [UIImage imageNamed:@"icon-tab-send-bg"];
    _icon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icon-tab-send"]];
    [self addSubview:self.icon];
    self.icon.center = CGPointMake(self.center.x + 3.0f, self.center.y + 6.0f);
  }
  return self;
}

@end
