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

#pragma mark - Init

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

#pragma mark - Settings

- (NSNumber*)send_to_self_onboarded
{
  return [_defaults valueForKey:[self keyForSetting:InfinitSendToSelfOnboarded]];
}

- (void)setSend_to_self_onboarded:(NSNumber*)send_to_self_onboarded
{
  [_defaults setValue:send_to_self_onboarded
               forKey:[self keyForSetting:InfinitSendToSelfOnboarded]];
}

- (NSString*)username
{
  return [_defaults valueForKey:[self keyForSetting:InfinitSettingUsername]];
}

- (void)setUsername:(NSString*)username
{
  [_defaults setValue:username.lowercaseString forKey:[self keyForSetting:InfinitSettingUsername]];
}

- (NSNumber*)welcome_onboarded
{
  return [_defaults valueForKey:[self keyForSetting:InfinitWelcomeOnboarded]];
}

- (void)setWelcome_onboarded:(NSNumber*)welcome_onboarded
{
  [_defaults setValue:welcome_onboarded forKey:[self keyForSetting:InfinitWelcomeOnboarded]];
}

#pragma mark - Enum

- (NSString*)keyForSetting:(InfinitSettings)setting
{
  switch (setting)
  {
    case InfinitSendToSelfOnboarded:
      return @"send_to_self_onboarded";
    case InfinitSettingUsername:
      return @"username";
    case InfinitWelcomeOnboarded:
      return @"welcome_onboarded";

    default:
      return nil;
  }
}

@end
