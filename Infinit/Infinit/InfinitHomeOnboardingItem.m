//
//  InfinitHomeOnboardingItem.m
//  Infinit
//
//  Created by Christopher Crone on 15/04/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitHomeOnboardingItem.h"

@implementation InfinitHomeOnboardingItem

- (instancetype)_initWithType:(InfinitHomeOnboardingCellType)type
{
  if (self = [super init])
  {
    _type = type;
  }
  return self;
}

+ (instancetype)initWithType:(InfinitHomeOnboardingCellType)type
{
  return [[InfinitHomeOnboardingItem alloc] _initWithType:type];
}

@end
