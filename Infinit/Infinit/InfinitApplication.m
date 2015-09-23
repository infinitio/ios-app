//
//  InfinitApplication.m
//  Infinit
//
//  Created by Christopher Crone on 04/06/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitApplication.h"

#import "AppDelegate.h"

@implementation InfinitApplication

- (void)sendEvent:(UIEvent*)event
{
  if (event && (event.subtype == UIEventSubtypeMotionShake))
  {
    AppDelegate* delegate = (AppDelegate*)[UIApplication sharedApplication].delegate;
    [delegate handleShakeEvent:event];
    [super sendEvent:event];
  }
  else
  {
    [super sendEvent:event];
  }
}

@end
