//
//  InfinitSettingsCell.m
//  Infinit
//
//  Created by Christopher Crone on 06/02/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitSettingsCell.h"

#import "InfinitColor.h"

@implementation InfinitSettingsCell

- (void)prepareForReuse
{
  [super prepareForReuse];
  self.title_label.textColor = [InfinitColor colorWithRed:81 green:73 blue:73];
}

@end
