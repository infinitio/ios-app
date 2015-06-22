//
//  InfinitSettingsToggleCell.m
//  Infinit
//
//  Created by Christopher Crone on 22/06/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitSettingsToggleCell.h"

@implementation InfinitSettingsToggleCell

- (void)prepareForReuse
{
  [self.switch_element removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
  [super prepareForReuse];
}

@end
