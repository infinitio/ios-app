//
//  InfinitWormhole.h
//  Infinit
//
//  Created by Christopher Crone on 09/04/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface InfinitWormhole : NSObject

+ (instancetype)sharedInstance;

- (void)registerForWormholeNotification:(NSString*)name
                               observer:(id)observer 
                               selector:(SEL)selector;
- (void)unregisterForWormholeNotifications:(id)observer;
- (void)unregisterAllObservers;

- (void)sendWormholeNotification:(NSString*)name;

@end
