//
//  InfinitStatusBarNotifier.h
//  Infinit
//
//  Created by Christopher Crone on 30/04/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, InfinitStatusBarNotificationType)
{
  InfinitStatusBarNotificationInfo,
  InfinitStatusBarNotificationWarn,
  InfinitStatusBarNotificationError,
};

@interface InfinitStatusBarNotifier : NSObject

+ (instancetype)sharedInstance;

- (void)showMessage:(NSString*)message
             ofType:(InfinitStatusBarNotificationType)type
           duration:(NSTimeInterval)duration;

- (void)showMessage:(NSString*)message
             ofType:(InfinitStatusBarNotificationType)type
           duration:(NSTimeInterval)duration
       withActivity:(BOOL)activity;

@end
