//
//  InfinitFacebookManager.m
//  Infinit
//
//  Created by Christopher Crone on 29/05/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitFacebookManager.h"

#import "InfinitApplicationSettings.h"

#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>

#import <Gap/InfinitConnectionManager.h>
#import <Gap/InfinitStateManager.h>

static InfinitFacebookManager* _instance = nil;
static dispatch_once_t _instance_token = 0;

@implementation InfinitFacebookManager

#pragma mark - Init

- (id)init
{
  NSCAssert(_instance == nil, @"Use sharedInstance");
  if (self = [super init])
  {
    _login_manager = [[FBSDKLoginManager alloc] init];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(connectionStatusChanged:)
                                                 name:INFINIT_CONNECTION_STATUS_CHANGE
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(clearModel)
                                                 name:INFINIT_CLEAR_MODEL_NOTIFICATION 
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(logout)
                                                 name:INFINIT_WILL_LOGOUT_NOTIFICATION 
                                               object:nil];
  }
  return self;
}

+ (instancetype)sharedInstance
{
  dispatch_once(&_instance_token, ^
  {
    _instance = [[InfinitFacebookManager alloc] init];
  });
  return _instance;
}

#pragma mark - Connection Changes

- (void)connectionStatusChanged:(NSNotification*)notification
{
  InfinitConnectionStatus* connection_status = notification.object;
  if (!connection_status.status && !connection_status.still_trying)
  {
    [self logout];
  }
}

#pragma mark - State Changes

- (void)clearModel
{
  _instance = nil;
  _instance_token = 0;
}

- (void)logout
{
  [InfinitApplicationSettings sharedInstance].login_method = InfinitLoginNone;
  if ([FBSDKAccessToken currentAccessToken])
    [self.login_manager logOut];
}

@end
