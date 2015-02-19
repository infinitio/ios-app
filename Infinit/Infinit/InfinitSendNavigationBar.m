//
//  InfinitSendNavigationBar.m
//  Infinit
//
//  Created by Christopher Crone on 20/01/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitSendNavigationBar.h"

#import "JDStatusBarNotification.h"

#import <Gap/InfinitConnectionManager.h>

@implementation InfinitSendNavigationBar

- (CGSize)sizeThatFits:(CGSize)size
{
  CGFloat height = 54.0f;
  if ([JDStatusBarNotification isVisible])
    height += [JDStatusBarNotification currentBar].bounds.size.height;
  return CGSizeMake(self.superview.bounds.size.width, height);
}

@end
