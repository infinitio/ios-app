//
//  InfinitFilesBottomBar.m
//  Infinit
//
//  Created by Christopher Crone on 25/02/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitFilesBottomBar.h"

@implementation InfinitFilesBottomBar

- (void)awakeFromNib
{
  _enabled = NO;
}

- (void)setEnabled:(BOOL)enabled
{
  if (self.enabled == enabled)
    return;
  _enabled = enabled;
  self.delete_button.enabled = enabled;
  self.send_button.enabled = enabled;
}

@end
