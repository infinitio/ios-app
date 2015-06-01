//
//  InfinitLocalNotificationManager.mm
//  Infinit
//
//  Created by Christopher Crone on 28/01/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitLocalNotificationManager.h"

#import <Gap/InfinitPeerTransactionManager.h>
#import <Gap/InfinitStateManager.h>
#import <Gap/InfinitUserManager.h>

#import <infinit/oracles/TransactionStatuses.hh>

#undef check
#import <elle/log.hh>

ELLE_LOG_COMPONENT("iOS.LocalNotifications");

using TransactionStatus = infinit::oracles::TransactionStatus;

@interface InfinitRemotePeerTransactionNotification : NSObject

@property (nonatomic, readonly) NSInteger file_count;
@property (nonatomic, readonly) NSString* recipient_device_id;
@property (nonatomic, readonly) NSString* recipient_fullname;
@property (nonatomic, readonly) NSString* recipient_id;
@property (nonatomic, readonly) TransactionStatus status;
@property (nonatomic, readonly) NSString* sender_device_id;
@property (nonatomic, readonly) NSString* sender_fullname;
@property (nonatomic, readonly) NSString* sender_id;

@property (nonatomic, readonly) BOOL send_to_self;
@property (nonatomic, readonly) BOOL receive_from_self;

- (id)initWithDictionary:(NSDictionary*)dictionary;

@end

@implementation InfinitRemotePeerTransactionNotification

- (id)initWithDictionary:(NSDictionary*)dictionary
{
  if (self = [super init])
  {
    _file_count = [dictionary[@"file_count"] integerValue];
    _recipient_device_id = dictionary[@"recipient_device"];
    _recipient_fullname = dictionary[@"recipient_name"];
    _recipient_id = dictionary[@"recipient"];
    NSString* status_str = dictionary[@"status"];
    if (status_str != nil)
      _status = static_cast<TransactionStatus>(status_str.intValue);
    _sender_device_id = dictionary[@"sender_device"];
    _sender_fullname = dictionary[@"sender_name"];
    _sender_id = dictionary[@"sender"];
  }
  return self;
}

- (BOOL)send_to_self
{
  NSString* self_device_id = [InfinitStateManager sharedInstance].self_device_id;
  if ([self.sender_id isEqualToString:self.recipient_id] &&
      [self.sender_device_id isEqualToString:self_device_id])
  {
    return YES;
  }
  return NO;
}

- (BOOL)receive_from_self
{
  NSString* self_device_id = [InfinitStateManager sharedInstance].self_device_id;
  if ([self.sender_id isEqualToString:self.recipient_id] &&
      ![self.sender_device_id isEqualToString:self_device_id])
  {
    return YES;
  }
  return NO;
}

@end

static InfinitLocalNotificationManager* _instance = nil;
static dispatch_once_t _instance_token = 0;

@implementation InfinitLocalNotificationManager

#pragma mark - init

- (id)init
{
  NSCAssert(_instance == nil, @"Use the sharedInstance");
  if (self = [super init])
  {
  }
  return self;
}

+ (instancetype)sharedInstance
{
  dispatch_once(&_instance_token, ^
  {
    ELLE_DUMP("%s: instatiate instance", self.description.UTF8String);
    _instance = [[InfinitLocalNotificationManager alloc] init];
  });
  return _instance;
}

#pragma mark - General

- (UIBackgroundFetchResult)localNotificationForRemoteNotification:(NSDictionary*)dictionary
{
  UIBackgroundFetchResult res;
  InfinitRemotePeerTransactionNotification* notification =
    [[InfinitRemotePeerTransactionNotification alloc] initWithDictionary:dictionary];
  if (notification.status == TransactionStatus::initialized)
    res = UIBackgroundFetchResultNewData;
  else
    res = UIBackgroundFetchResultNoData;
  UILocalNotification* user_notification = [[UILocalNotification alloc] init];
  user_notification.fireDate = [NSDate date];
  // Can only get meaningful information if we're logged into state.
  if ([InfinitStateManager sharedInstance].logged_in)
  {
    InfinitUser* me = [[InfinitUserManager sharedInstance] me];
    NSString* self_device_id = [[InfinitStateManager sharedInstance] self_device_id];
    if ([notification.sender_id isEqualToString:me.meta_id] &&
        [notification.sender_device_id isEqualToString:self_device_id]) // Sender
    {
      user_notification.alertBody = [self senderBodyForNotification:notification];
    }
    else // Recipient
    {
      user_notification.alertBody = [self recipientBodyForNotification:notification];
    }
    if (user_notification.alertBody.length > 0)
    {
      if (notification.status == TransactionStatus::initialized)
      {
        NSInteger badge_count = 0;
        NSArray* transactions = [InfinitPeerTransactionManager sharedInstance].transactions;
        for (InfinitPeerTransaction* transaction in transactions)
        {
          if (transaction.receivable)
            badge_count++;
        }
        user_notification.applicationIconBadgeNumber = badge_count;
      }
    }
  }
  else
  {
    NSString* files = notification.file_count == 1 ? NSLocalizedString(@"file", nil) :
                                                     NSLocalizedString(@"files", nil);
    switch (notification.status)
    {
      case TransactionStatus::initialized:
        // Assume recipient.
        user_notification.alertBody =
          [NSString stringWithFormat:NSLocalizedString(@"%@ wants to send %ld %@ to you", nil),
           notification.sender_fullname, notification.file_count, files];
        user_notification.applicationIconBadgeNumber = 1;
        break;
      case TransactionStatus::rejected:
        // Assume sender.
        user_notification.alertBody =
          [NSString stringWithFormat:NSLocalizedString(@"%@ declined your transfer!", nil),
           notification.recipient_fullname];
        break;
      case TransactionStatus::finished:
        // Assume sender.
        user_notification.alertBody =
          [NSString stringWithFormat:NSLocalizedString(@"%@ received your files!", nil),
           notification.recipient_fullname];
        break;

      default:
        break;
    }
  }
  if (user_notification.alertBody.length > 0)
    [[UIApplication sharedApplication] scheduleLocalNotification:user_notification];
  return res;
}

- (void)backgroundTaskAboutToBeKilledForTransaction:(InfinitPeerTransaction*)transaction
{
  UILocalNotification* user_notification = [[UILocalNotification alloc] init];
  user_notification.fireDate = [NSDate date];
  switch (transaction.status)
  {
    case gap_transaction_new:
      user_notification.alertBody =
        NSLocalizedString(@"Oh no! Infinit can't connect. Retry?", nil);
      break;
    case gap_transaction_connecting:
    case gap_transaction_transferring:
      user_notification.alertBody =
        NSLocalizedString(@"Open Infinit to ensure your transfer continues", nil);
      break;

    default:
      return;
  }
  [[UIApplication sharedApplication] scheduleLocalNotification:user_notification];
}

#pragma mark - Helpers

- (NSString*)recipientBodyForNotification:(InfinitRemotePeerTransactionNotification*)notification
{
  NSString* res = nil;
  NSString* files = notification.file_count == 1 ? NSLocalizedString(@"file", nil) :
                                                   NSLocalizedString(@"files", nil);
  switch (notification.status)
  {
    case TransactionStatus::initialized:
      if (notification.receive_from_self)
        res = [NSString stringWithFormat:NSLocalizedString(@"You'd like to send %ld %@", nil),
               notification.file_count, files];
      else
        res = [NSString stringWithFormat:NSLocalizedString(@"%@ wants to send %ld %@ to you", nil),
               notification.sender_fullname, notification.file_count, files];
      break;

    default:
      break;
  }
  return res;
}

- (NSString*)senderBodyForNotification:(InfinitRemotePeerTransactionNotification*)notification
{
  NSString* res = nil;
  switch (notification.status)
  {
    case TransactionStatus::rejected:
      if (notification.send_to_self)
        res = [NSString stringWithFormat:NSLocalizedString(@"You declined the transfer!", nil)];
      else
        res = [NSString stringWithFormat:NSLocalizedString(@"%@ declined the transfer!", nil),
               notification.recipient_fullname];
      break;
    case TransactionStatus::finished:
      if (notification.send_to_self)
        res = [NSString stringWithFormat:NSLocalizedString(@"Received your files!", nil)];
      else
        res = [NSString stringWithFormat:NSLocalizedString(@"%@ received your files!", nil),
               notification.recipient_fullname];
      break;

    default:
      break;
  }
  return res;
}

@end