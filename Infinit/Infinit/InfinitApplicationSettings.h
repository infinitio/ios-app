//
//  InfinitApplicationSettings.h
//  Infinit
//
//  Created by Christopher Crone on 12/01/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, InfinitSettings)
{
  InfinitSettingRatedApp,
  InfinitSettingRatingTransactions,
  InfinitSettingSendToSelfOnboarded,
  InfinitSettingUsername,
  InfinitSettingWelcomeOnboarded,
};

@interface InfinitApplicationSettings : NSObject

+ (instancetype)sharedInstance;

@property (nonatomic, readwrite) BOOL rated_app;
@property (nonatomic, readwrite) NSNumber* rating_transactions;
@property (nonatomic, readwrite) NSNumber* send_to_self_onboarded;
@property (nonatomic, readwrite) NSString* username;
@property (nonatomic, readwrite) NSNumber* welcome_onboarded;

@end
