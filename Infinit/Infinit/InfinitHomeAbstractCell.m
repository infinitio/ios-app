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

- (void)awakeFromNib
{
  self.layer.cornerRadius = 3.0f;
  self.layer.masksToBounds = NO;
  self.layer.shadowOpacity = 0.15f;
  self.layer.shadowRadius = 2.0f;
  self.layer.shadowColor = [UIColor blackColor].CGColor;
  self.layer.shadowOffset = CGSizeMake(0.0f, 1.0f);
  self.layer.shadowPath =
    [UIBezierPath bezierPathWithRoundedRect:self.bounds cornerRadius:3.0f].CGPath;
}

- (void)prepareForReuse
{
  self.alpha = 1.0f;
}

@end
