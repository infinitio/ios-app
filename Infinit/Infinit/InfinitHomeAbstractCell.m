//
//  InfinitHomeAbstractCell.m
//  Infinit
//
//  Created by Christopher Crone on 20/01/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitHomeAbstractCell.h"

#import "InfinitColor.h"

@implementation InfinitHomeAbstractCell

- (void)awakeFromNib
{
  self.layer.masksToBounds = NO;
  self.layer.shadowOpacity = 0.75f;
  self.layer.shadowRadius = 1.5f;
  self.layer.shadowColor = [InfinitColor colorWithGray:0 alpha:0.3f].CGColor;
  self.layer.shadowOffset = CGSizeMake(0.0f, 1.0f);
}

@end
