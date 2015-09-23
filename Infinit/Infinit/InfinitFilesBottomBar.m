//
//  InfinitFilesBottomBar.m
//  Infinit
//
//  Created by Christopher Crone on 25/02/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitFilesBottomBar.h"

#import "InfinitHostDevice.h"

#import <Gap/InfinitConnectionManager.h>

@implementation InfinitFilesBottomBar

- (void)awakeFromNib
{
  _enabled = NO;
  self.translatesAutoresizingMaskIntoConstraints = NO;
  if ([InfinitHostDevice iOS7])
  {
    self.share_button.hidden = YES;
  }
}

- (void)setEnabled:(BOOL)enabled
{
  if (self.enabled == enabled)
    return;
  _enabled = enabled;
  self.delete_button.enabled = enabled;
  self.send_button.enabled = enabled && [InfinitConnectionManager sharedInstance].was_logged_in;
  self.share_button.enabled = enabled && ![InfinitHostDevice iOS7];
}

@end
