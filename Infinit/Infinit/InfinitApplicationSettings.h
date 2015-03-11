//
//  InfinitApplicationSettings.h
//  Infinit
//
//  Created by Christopher Crone on 12/01/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface InfinitApplicationSettings : NSObject

@property (nonatomic, readwrite) BOOL asked_notifications;
@property (nonatomic, readwrite) BOOL been_launched;
@property (nonatomic, readwrite) BOOL rated_app;
@property (nonatomic, readwrite) NSNumber* rating_transactions;
@property (nonatomic, readwrite) NSNumber* send_to_self_onboarded;
@property (nonatomic, readwrite) NSString* username;
@property (nonatomic, readwrite) NSNumber* welcome_onboarded;

/// Home screen onboarding.
@property (nonatomic, readwrite) BOOL home_onboarded_swipe;
@property (nonatomic, readwrite) BOOL home_onboarded_notifications;
@property (nonatomic, readwrite) BOOL home_onboarded_normal_send;
@property (nonatomic, readwrite) BOOL home_onboarded_ghost_send;
@property (nonatomic, readwrite) BOOL home_onboarded_self_send;
@property (nonatomic, readwrite) BOOL home_onboarded_background;

+ (instancetype)sharedInstance;

@end
