//
//  InfinitWormhole.m
//  Infinit
//
//  Created by Christopher Crone on 09/04/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitWormhole.h"

@interface InfinitWormhole ()

@property (atomic, readonly) NSMutableDictionary* notifications_map;

@end

static InfinitWormhole* _instance = nil;
static dispatch_once_t _instance_token = 0;

@implementation InfinitWormhole

#pragma mark - Init

- (void)dealloc
{
  CFNotificationCenterRemoveEveryObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                          (__bridge const void*)self);
  for (NSString* notification in self.notifications_map.allKeys)
  {
    NSArray* observers = self.notifications_map[notification];
    for (id observer in observers)
    {
      @try
      {
        [[NSNotificationCenter defaultCenter] removeObserver:observer forKeyPath:notification];
      }
      @catch (NSException* exception)
      {}
    }
  }
  _notifications_map = nil;
}

+ (instancetype)sharedInstance
{
  dispatch_once(&_instance_token, ^
  {
    _instance = [[InfinitWormhole alloc] init];
  });
  return _instance;
}

#pragma mark - Notification Handling

- (void)registerForWormholeNotification:(NSString*)name
                               observer:(id)observer
                               selector:(SEL)selector
{
  @synchronized(self)
  {
    if (self.notifications_map == nil)
      _notifications_map = [NSMutableDictionary dictionary];
    NSArray* observers = [self.notifications_map objectForKey:name];
    if (!observers || observers.count == 0)
    {
      CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                      (__bridge const void*)self,
                                      wormholeNotificationCallback,
                                      (__bridge CFStringRef)name,
                                      NULL,
                                      0);
    }
    else if ([observers containsObject:observer])
    {
      return;
    }
    if (!observers)
    {
      observers = [NSArray arrayWithObject:observer];
    }
    else
    {
      NSMutableArray* temp = [observers mutableCopy];
      [temp addObject:observer];
      observers = [temp copy];
    }
    [[NSNotificationCenter defaultCenter] addObserver:observer
                                             selector:selector 
                                                 name:name 
                                               object:nil];
    [self.notifications_map setObject:observers forKey:name];
  }
}

- (void)unregisterForWormholeNotifications:(id)observer
{
  @synchronized(self)
  {
    NSMutableArray* notifications = [NSMutableArray array];
    for (NSString* notification in self.notifications_map.allKeys)
    {
      if ([self.notifications_map[notification] containsObject:observer])
        [notifications addObject:notification];
    }
    for (NSString* notification in notifications)
    {
      [[NSNotificationCenter defaultCenter] removeObserver:observer name:notification object:nil];
      NSMutableArray* observers = [self.notifications_map[notification] mutableCopy];
      [observers removeObject:observer];
      if (observers.count == 0)
      {
        [self.notifications_map removeObjectForKey:notification];
        CFNotificationCenterRemoveObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                           (__bridge const void*)self,
                                           (__bridge CFStringRef)notification,
                                           NULL);
      }
      else
      {
        [self.notifications_map setObject:[observers copy] forKey:notification];
      }
    }
  }
}

- (void)unregisterAllObservers
{
  _instance = nil;
  _instance_token = 0;
}

- (void)sendWormholeNotification:(NSString*)name
{
  CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(),
                                       (__bridge CFStringRef)name,
                                       NULL,
                                       NULL,
                                       0);
}

#pragma mark - Helpers

void wormholeNotificationCallback(CFNotificationCenterRef center,
                                  void* observer,
                                  CFStringRef name,
                                  void const* object,
                                  CFDictionaryRef user_info)
{
  dispatch_async(dispatch_get_main_queue(), ^
  {
    [[NSNotificationCenter defaultCenter] postNotificationName:(__bridge NSString*)name
                                                        object:(__bridge id)object
                                                      userInfo:(__bridge NSDictionary*)user_info];
  });
}

@end
