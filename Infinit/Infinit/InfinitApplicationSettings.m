//
//  InfinitApplicationSettings.m
//  Infinit
//
//  Created by Christopher Crone on 12/01/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitApplicationSettings.h"

static InfinitApplicationSettings* _instance = nil;

@implementation InfinitApplicationSettings
{
@private
  NSUserDefaults* _defaults;
}

#pragma mark Init

- (id)init
{
  NSCAssert(_instance == nil, @"Use the sharedInstance");
  if (self = [super init])
  {
    _defaults = [NSUserDefaults standardUserDefaults];
  }
  return self;
}

+ (instancetype)sharedInstance
{
  if (_instance == nil)
    _instance = [[InfinitApplicationSettings alloc] init];
  return _instance;
}

#pragma mark Settings

- (NSString*)username
{
  return [_defaults valueForKey:[self keyForSetting:InfinitSettingUsername]];
}

- (void)setUsername:(NSString*)username
{
  [_defaults setValue:username.lowercaseString forKey:[self keyForSetting:InfinitSettingUsername]];
}

#pragma mark Enum

- (NSString*)keyForSetting:(InfinitSettings)setting
{
  switch (setting)
  {
    case InfinitSettingUsername:
      return @"username";

    default:
      return nil;
  }
}

@end
