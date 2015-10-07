//
//  InfinitApplicationSettings.h
//  Infinit
//
//  Created by Christopher Crone on 12/01/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, InfinitLoginMethod)
{
  InfinitLoginEmail    = 0,
  InfinitLoginFacebook = 1,

  InfinitLoginNone     = -1,
};

@interface InfinitApplicationSettings : NSObject

@property (atomic, readwrite) BOOL address_book_uploaded;
@property (atomic, readwrite) BOOL asked_notifications;
@property (atomic, readwrite) BOOL autosave_to_gallery;
@property (atomic, readwrite) BOOL been_launched;
@property (atomic, readwrite) NSUInteger launch_count;
@property (atomic, readwrite) InfinitLoginMethod login_method;
@property (atomic, readwrite) BOOL rated_app;
@property (atomic, readwrite) NSNumber* rating_transactions;
@property (atomic, readwrite) NSNumber* send_to_self_onboarded;
@property (atomic, readwrite) BOOL stored_device_id;
@property (atomic, readwrite) NSString* username;
@property (atomic, readwrite) NSNumber* welcome_onboarded;

/// Home screen onboarding.
@property (atomic, readwrite) BOOL home_onboarded_swipe;
@property (atomic, readwrite) BOOL home_onboarded_notifications;
@property (atomic, readwrite) BOOL home_onboarded_normal_send;
@property (atomic, readwrite) BOOL home_onboarded_ghost_send;
@property (atomic, readwrite) BOOL home_onboarded_self_send;
@property (atomic, readwrite) BOOL home_onboarded_background;

+ (instancetype)sharedInstance;

- (void)resetOnboarding;

@end
