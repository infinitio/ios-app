//
//  InfinitSettingsCell.m
//  Infinit
//
//  Created by Christopher Crone on 06/02/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitSettingsCell.h"

#import <Gap/InfinitColor.h>

@implementation InfinitSettingsCell

- (void)prepareForReuse
{
  self.title_label.textColor = [InfinitColor colorWithRed:81 green:81 blue:73];
}

@end
