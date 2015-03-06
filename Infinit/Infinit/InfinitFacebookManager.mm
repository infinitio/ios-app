//
//  InfinitFacebookManager.m
//  Infinit
//
//  Created by Christopher Crone on 02/03/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitFacebookManager.h"

#import <Gap/InfinitStateManager.h>

#undef check
#import <elle/log.hh>

ELLE_LOG_COMPONENT("iOS.FacebookManager");

static InfinitFacebookManager* _instance = nil;

@implementation InfinitFacebookManager

#pragma mark - Init

- (id)init
{
  NSCAssert(_instance == nil, @"Use sharedInstance");
  if (self = [super init])
  {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(clearModel)
                                                 name:INFINIT_CLEAR_MODEL_NOTIFICATION
                                               object:nil];
  }
  return self;
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

+ (instancetype)sharedInstance
{
  if (_instance == nil)
    _instance = [[InfinitFacebookManager alloc] init];
  return _instance;
}

#pragma mark - General

- (NSArray*)permission_list
{
  return @[@"public_profile", @"email", @"user_friends"];
}

- (void)sessionStateChanged:(FBSession*)session
                      state:(FBSessionState)state
                      error:(NSError*)error
{
  if (!error && state == FBSessionStateOpen)
  {
    ELLE_TRACE("%s: facebook session open", self.description.UTF8String);
  }
  else if (state == FBSessionStateClosed || state == FBSessionStateClosedLoginFailed)
  {
    ELLE_TRACE("%s: facebook session %s",
               self.description.UTF8String, state == FBSessionStateClosed ? "closed" : "failed");
  }
  if (error)
  {
    ELLE_WARN("%s: got error: %s", self.description.UTF8String, error.description.UTF8String);
    [self cleanSession];
  }
  NSMutableDictionary* dict = [NSMutableDictionary dictionaryWithDictionary:@{@"state": @(state)}];
  if (error)
    dict[@"error"] = error;
  NSNotification* notification =
    [NSNotification notificationWithName:INFINIT_FACEBOOK_SESSION_STATE_CHANGED
                                  object:nil
                                userInfo:dict];
  [[NSNotificationCenter defaultCenter] postNotification:notification];
}

- (void)_cleanSession
{
  [FBSession.activeSession closeAndClearTokenInformation];
}

- (void)cleanSession
{
  [self performSelectorOnMainThread:@selector(_cleanSession) withObject:nil waitUntilDone:YES];
}

- (void)_closeSession
{
  [FBSession.activeSession close];
}

- (void)closeSession
{
  [self performSelectorOnMainThread:@selector(_closeSession) withObject:nil waitUntilDone:YES];
}

#pragma mark - Helpers

- (void)clearModel
{
  _instance = nil;
}

@end
