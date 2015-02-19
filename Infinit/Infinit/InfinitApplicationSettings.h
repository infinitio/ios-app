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
@property (nonatomic, readwrite) BOOL rated_app;
@property (nonatomic, readwrite) NSNumber* rating_transactions;
@property (nonatomic, readwrite) NSNumber* send_to_self_onboarded;
@property (nonatomic, readwrite) NSString* username;
@property (nonatomic, readwrite) NSNumber* welcome_onboarded;

+ (instancetype)sharedInstance;

@end
