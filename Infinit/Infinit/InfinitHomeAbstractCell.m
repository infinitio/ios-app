//
//  InfinitHomeAbstractCell.m
//  Infinit
//
//  Created by Christopher Crone on 20/01/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitHomeAbstractCell.h"

#import "InfinitColor.h"
#import "InfinitHostDevice.h"

@implementation InfinitHomeAbstractCell

- (void)layoutSubviews
{
  [super layoutSubviews];
  if ([InfinitHostDevice deviceCPU] >= InfinitCPUType_ARM64_v8 && self.layer.shadowPath == nil)
  {
    self.layer.shadowPath =
      [UIBezierPath bezierPathWithRoundedRect:self.bounds cornerRadius:3.0f].CGPath;
  }
}

- (void)awakeFromNib
{
  self.layer.rasterizationScale = [InfinitHostDevice screenScale];
  self.layer.shouldRasterize = YES;
}

@end
