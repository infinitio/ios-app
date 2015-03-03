//
//  InfinitFacebookManager.m
//  Infinit
//
//  Created by Christopher Crone on 02/03/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitFacebookManager.h"

static InfinitFacebookManager* _instance = nil;

@implementation InfinitFacebookManager

#pragma mark - Init

- (id)init
{
  NSCAssert(_instance == nil, @"Use sharedInstance");
  if (self = [super init])
  {
  }
  return self;
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
  // If the session was opened successfully
  if (!error && state == FBSessionStateOpen)
  {
    NSLog(@"Session opened");
    // Take the information and add it to InfinitUserObject.
    [[FBRequest requestForMe] startWithCompletionHandler:^(FBRequestConnection* connection,
                                                           NSDictionary<FBGraphUser>* fb_user,
                                                           NSError* error)
     {
       if (error)
       {
         // Handle error
       }
       else
       {
         _user_name = fb_user.name;
         NSData* avatar_data =
          [NSData dataWithContentsOfURL:[self avatarURLForUserWithId:fb_user.objectID]];
         _user_avatar = [UIImage imageWithData:avatar_data];
       }
     }];
    return;
  }
  if (state == FBSessionStateClosed || state == FBSessionStateClosedLoginFailed)
  {
    // If the session is closed
    NSLog(@"Session closed");
  }
  if (error)
  {
    // Clear this token
    [self cleanSession];
  }
}

- (void)cleanSession
{
  [FBSession.activeSession closeAndClearTokenInformation];
}

- (void)closeSession
{
  [FBSession.activeSession close];
}

#pragma mark - Helpers

- (NSURL*)avatarURLForUserWithId:(NSString*)id_
{
  NSString* str =
    [NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=large", id_];
  return [NSURL URLWithString:str];
}

@end
