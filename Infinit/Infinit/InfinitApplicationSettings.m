//
//  InfinitApplicationSettings.m
//  Infinit
//
//  Created by Christopher Crone on 12/01/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitApplicationSettings.h"

typedef NS_ENUM(NSUInteger, InfinitSettings)
{
  InfinitSettingAskedNotifications,
  InfinitSettingRatedApp,
  InfinitSettingRatingTransactions,
  InfinitSettingSendToSelfOnboarded,
  InfinitSettingUsername,
  InfinitSettingWelcomeOnboarded,
};

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

- (BOOL)asked_notifications
{
  NSNumber* res = [_defaults valueForKey:[self keyForSetting:InfinitSettingAskedNotifications]];
  if (res != nil && res.boolValue)
    return YES;
  return NO;
}

- (void)setAsked_notifications:(BOOL)asked_notifications
{
  [_defaults setValue:@(asked_notifications)
               forKey:[self keyForSetting:InfinitSettingAskedNotifications]];
}

- (BOOL)rated_app
{
  NSNumber* res = [_defaults valueForKey:[self keyForSetting:InfinitSettingRatedApp]];
  if (res != nil && res.boolValue)
    return YES;
  return NO;
}

- (void)setRated_app:(BOOL)rated_app
{
  [_defaults setValue:@(rated_app) forKey:[self keyForSetting:InfinitSettingRatedApp]];
}

- (NSNumber*)rating_transactions
{
  return [_defaults valueForKey:[self keyForSetting:InfinitSettingRatingTransactions]];
}

- (void)setRating_transactions:(NSNumber*)rating_transactions
{
  [_defaults setValue:rating_transactions
               forKey:[self keyForSetting:InfinitSettingRatingTransactions]];
}

- (NSNumber*)send_to_self_onboarded
{
  return [_defaults valueForKey:[self keyForSetting:InfinitSettingSendToSelfOnboarded]];
}

- (void)setSend_to_self_onboarded:(NSNumber*)send_to_self_onboarded
{
  [_defaults setValue:send_to_self_onboarded
               forKey:[self keyForSetting:InfinitSettingSendToSelfOnboarded]];
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
  return [_defaults valueForKey:[self keyForSetting:InfinitSettingWelcomeOnboarded]];
}

- (void)setWelcome_onboarded:(NSNumber*)welcome_onboarded
{
  [_defaults setValue:welcome_onboarded forKey:[self keyForSetting:InfinitSettingWelcomeOnboarded]];
}

#pragma mark - Enum

- (NSString*)keyForSetting:(InfinitSettings)setting
{
  switch (setting)
  {
    case InfinitSettingAskedNotifications:
      return @"asked_notifications";
    case InfinitSettingRatedApp:
      return @"rated_app";
    case InfinitSettingRatingTransactions:
      return @"rating_transactions";
    case InfinitSettingSendToSelfOnboarded:
      return @"send_to_self_onboarded";
    case InfinitSettingUsername:
      return @"username";
    case InfinitSettingWelcomeOnboarded:
      return @"welcome_onboarded";

    default:
      return @"";
  }
}

@end
