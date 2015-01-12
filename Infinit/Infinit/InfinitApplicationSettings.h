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
  InfinitSettingUsername,
};

@interface InfinitApplicationSettings : NSObject

+ (instancetype)sharedInstance;

@property (nonatomic, readwrite) NSString* username;

@end
