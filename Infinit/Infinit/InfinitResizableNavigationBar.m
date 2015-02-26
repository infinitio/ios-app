//
//  InfinitResizableNavigationBar.m
//  Infinit
//
//  Created by Christopher Crone on 21/02/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitResizableNavigationBar.h"

@implementation InfinitResizableNavigationBar

- (CGSize)sizeThatFits:(CGSize)size
{
  if (self.large)
    return CGSizeMake(self.superview.bounds.size.width, 54.0f);
  return [super sizeThatFits:size];
}

- (void)setLarge:(BOOL)large
{
  if (self.large == large)
    return;
  _large = large;
}

@end
