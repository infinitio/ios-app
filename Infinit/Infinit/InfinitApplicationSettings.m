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
  InfinitSettingBeenLaunched,
  InfinitSettingRatedApp,
  InfinitSettingRatingTransactions,
  InfinitSettingSendToSelfOnboarded,
  InfinitSettingUsername,
  InfinitSettingWelcomeOnboarded,
  // Home onboarding
  InfinitSettingHomeOnboardedInitial,
  InfinitSettingHomeOnboardedNormalSend,
  InfinitSettingHomeOnboardedGhostSend,
  InfinitSettingHomeOnboardedSelfSend,
  InfinitSettingHomeOnboardedBackground,
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
  return [self boolFromNumber:[_defaults valueForKey:[self keyForSetting:InfinitSettingAskedNotifications]]];
}

- (void)setAsked_notifications:(BOOL)asked_notifications
{
  [_defaults setValue:@(asked_notifications)
               forKey:[self keyForSetting:InfinitSettingAskedNotifications]];
}

- (BOOL)been_launched
{
  return [self boolFromNumber:[_defaults valueForKey:[self keyForSetting:InfinitSettingBeenLaunched]]];
}

- (void)setBeen_launched:(BOOL)been_launched
{
  [_defaults setValue:@(been_launched) forKey:[self keyForSetting:InfinitSettingBeenLaunched]];
}

- (BOOL)rated_app
{
  return [self boolFromNumber:[_defaults valueForKey:[self keyForSetting:InfinitSettingRatedApp]]];
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

#pragma mark - Home Onboarding

- (BOOL)home_onboarded_initial
{
  return [self boolFromNumber:[_defaults valueForKey:[self keyForSetting:InfinitSettingHomeOnboardedInitial]]];
}

- (void)setHome_onboarded_initial:(BOOL)home_onboarded_initial
{
  [_defaults setValue:@(home_onboarded_initial)
               forKey:[self keyForSetting:InfinitSettingHomeOnboardedInitial]];
}

- (BOOL)home_onboarded_normal_send
{
  return [self boolFromNumber:[_defaults valueForKey:[self keyForSetting:InfinitSettingHomeOnboardedNormalSend]]];
}

- (void)setHome_onboarded_normal_send:(BOOL)home_onboarded_normal_send
{
  [_defaults setValue:@(home_onboarded_normal_send)
               forKey:[self keyForSetting:InfinitSettingHomeOnboardedNormalSend]];
}

- (BOOL)home_onboarded_ghost_send
{
  return [self boolFromNumber:[_defaults valueForKey:[self keyForSetting:InfinitSettingHomeOnboardedGhostSend]]];
}

- (void)setHome_onboarded_ghost_send:(BOOL)home_onboarded_ghost_send
{
  [_defaults setValue:@(home_onboarded_ghost_send)
               forKey:[self keyForSetting:InfinitSettingHomeOnboardedGhostSend]];
}

- (BOOL)home_onboarded_self_send
{
  return [self boolFromNumber:[_defaults valueForKey:[self keyForSetting:InfinitSettingHomeOnboardedSelfSend]]];
}

- (void)setHome_onboarded_self_send:(BOOL)home_onboarded_self_send
{
  [_defaults setValue:@(home_onboarded_self_send)
               forKey:[self keyForSetting:InfinitSettingHomeOnboardedSelfSend]];
}

- (BOOL)home_onboarded_background
{
  return [self boolFromNumber:[_defaults valueForKey:[self keyForSetting:InfinitSettingHomeOnboardedBackground]]];
}

- (void)setHome_onboarded_background:(BOOL)home_onboarded_background
{
  [_defaults setValue:@(home_onboarded_background)
               forKey:[self keyForSetting:InfinitSettingHomeOnboardedBackground]];
}

#pragma mark - Enum

- (NSString*)keyForSetting:(InfinitSettings)setting
{
  switch (setting)
  {
    case InfinitSettingAskedNotifications:
      return @"asked_notifications";
    case InfinitSettingBeenLaunched:
      return @"been_launched";
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
    case InfinitSettingHomeOnboardedBackground:
      return @"home_onboarded_background";
    case InfinitSettingHomeOnboardedGhostSend:
      return @"home_onboarded_ghost_send";
    case InfinitSettingHomeOnboardedInitial:
      return @"home_onboarded_initial";
    case InfinitSettingHomeOnboardedNormalSend:
      return @"home_onboarded_normal_send";
    case InfinitSettingHomeOnboardedSelfSend:
      return @"home_onboarded_self_send";
  }
}

#pragma mark - Helpers

- (BOOL)boolFromNumber:(NSNumber*)number
{
  if (number == nil)
    return NO;
  return  number.boolValue;
}

@end
