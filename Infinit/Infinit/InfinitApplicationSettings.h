//
//  InfinitApplicationSettings.h
//  Infinit
//
//  Created by Christopher Crone on 12/01/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface InfinitApplicationSettings : NSObject

@property (atomic, readwrite) BOOL address_book_uploaded;
@property (atomic, readwrite) BOOL asked_notifications;
@property (atomic, readwrite) BOOL been_launched;
@property (atomic, readwrite) BOOL rated_app;
@property (atomic, readwrite) NSNumber* rating_transactions;
@property (atomic, readwrite) NSNumber* send_to_self_onboarded;
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

@end
