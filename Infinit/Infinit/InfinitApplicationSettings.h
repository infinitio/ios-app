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
  InfinitSendToSelfOnboarded,
  InfinitSettingUsername,
};

@interface InfinitApplicationSettings : NSObject

+ (instancetype)sharedInstance;

@property (nonatomic, readwrite) NSNumber* send_to_self_onboarded;
@property (nonatomic, readwrite) NSString* username;

@end
