//
//  InfinitLocalNotificationManager.h
//  Infinit
//
//  Created by Christopher Crone on 28/01/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import <Gap/InfinitPeerTransaction.h>

@interface InfinitLocalNotificationManager : NSObject

+ (instancetype)sharedInstance;

- (UIBackgroundFetchResult)localNotificationForRemoteNotification:(NSDictionary*)dictionary;

- (void)backgroundTaskAboutToBeKilledForTransaction:(InfinitPeerTransaction*)transaction;

@end
