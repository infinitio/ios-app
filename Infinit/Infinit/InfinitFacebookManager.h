//
//  InfinitFacebookManager.h
//  Infinit
//
//  Created by Christopher Crone on 02/03/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <FacebookSDK/FacebookSDK.h>

#define INFINIT_FACEBOOK_SESSION_STATE_CHANGED @"INFINIT_FACEBOOK_SESSION_STATE_CHANGED"

@interface InfinitFacebookManager : NSObject

@property (nonatomic, readonly) NSArray* permission_list;

+ (instancetype)sharedInstance;

- (void)sessionStateChanged:(FBSession*)session
                      state:(FBSessionState)state
                      error:(NSError*)error;

- (void)cleanSession;
- (void)closeSession;

@end
