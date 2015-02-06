//
//  InfinitHomeOnboardingCell.m
//  Infinit
//
//  Created by Christopher Crone on 20/01/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitHomeOnboardingCell.h"

#import "InfinitColor.h"
#import "InfinitHostDevice.h"

@implementation InfinitHomeOnboardingCell

- (void)awakeFromNib
{
  [super awakeFromNib];
  if ([InfinitHostDevice deviceCPU] >= InfinitCPUType_ARM64_v8)
  {
    self.layer.cornerRadius = 3.0f;
    self.layer.masksToBounds = NO;
    self.layer.shadowOpacity = 0.15f;
    self.layer.shadowRadius = 2.0f;
    self.layer.shadowColor = [InfinitColor colorWithGray:0].CGColor;
    self.layer.shadowOffset = CGSizeMake(0.0f, 1.0f);
  }
}

@end
