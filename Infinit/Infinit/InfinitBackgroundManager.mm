//
//  InfinitBackgroundManager.m
//  Infinit
//
//  Created by Christopher Crone on 30/01/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitBackgroundManager.h"

#import <Gap/InfinitPeerTransactionManager.h>
#import <Gap/InfinitStateManager.h>

#import <UIKit/UIKit.h>

#undef check
#import <elle/log.hh>

ELLE_LOG_COMPONENT("iOS.BackgroundManager");

@interface InfinitBackgroundManager ()

@property (nonatomic, readonly) NSMutableDictionary* task_map;

@end

static InfinitBackgroundManager* _instance = nil;

@implementation InfinitBackgroundManager

#pragma mark - Init

- (id)init
{
  NSCAssert(_instance == nil, @"Use sharedInstance");
  if (self = [super init])
  {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(transactionUpdated:)
                                                 name:INFINIT_PEER_TRANSACTION_STATUS_NOTIFICATION 
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(clearModel:)
                                                 name:INFINIT_CLEAR_MODEL_NOTIFICATION
                                               object:nil];
    [self fillMap];
  }
  return self;
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  for (NSNumber* task_num in self.task_map)
  {
    UIBackgroundTaskIdentifier task = task_num.unsignedIntegerValue;
    [[UIApplication sharedApplication] endBackgroundTask:task];
  }
}

+ (instancetype)sharedInstance
{
  if (_instance == nil)
    _instance = [[InfinitBackgroundManager alloc] init];
  return _instance;
}

- (void)fillMap
{
  NSArray* transactions = [InfinitPeerTransactionManager sharedInstance].transactions;
  for (InfinitPeerTransaction* transaction in transactions)
  {
    if (transaction.status == gap_transaction_transferring)
      [self addTaskForTransaction:transaction];
  }
}

- (void)clearModel:(NSNotification*)notification
{
  for (NSNumber* task_num in self.task_map)
  {
    UIBackgroundTaskIdentifier task = task_num.unsignedIntegerValue;
    [[UIApplication sharedApplication] endBackgroundTask:task];
  }
  _instance = nil;
}

#pragma mark - Transaction Updated

- (void)transactionUpdated:(NSNotification*)notification
{
  NSNumber* id_ = notification.userInfo[@"id"];
  InfinitPeerTransaction* transaction =
    [[InfinitPeerTransactionManager sharedInstance] transactionWithId:id_];
  if (transaction.status == gap_transaction_transferring)
  {
    [self addTaskForTransaction:transaction];
  }
  else // transaction not transferring
  {
    NSNumber* task_num = [self.task_map objectForKey:transaction.meta_id];
    if (task_num != nil)
    {
      ELLE_TRACE("%s: background task done for transaction: %s",
                 self.description.UTF8String, transaction.meta_id.UTF8String);
      [[UIApplication sharedApplication] endBackgroundTask:task_num.unsignedIntegerValue];
      [self.task_map removeObjectForKey:transaction.meta_id];
    }
  }
}

#pragma mark - Helpers

- (void)addTaskForTransaction:(InfinitPeerTransaction*)transaction
{
  if (self.task_map == nil)
    _task_map = [NSMutableDictionary dictionary];
  NSString* task_name =
    [NSString stringWithFormat:@"transfer transaction(%@)", transaction.meta_id];
  UIBackgroundTaskIdentifier task =
  [[UIApplication sharedApplication] beginBackgroundTaskWithName:task_name
                                               expirationHandler:^
   {
     ELLE_LOG("%s: background task killed: %s",
              self.description.UTF8String, task_name.description.UTF8String);
     if (task != UIBackgroundTaskInvalid)
     {
       [self.task_map removeObjectForKey:@(task)];
       [[UIApplication sharedApplication] endBackgroundTask:task];
     }
     else
     {
       [self.task_map removeObjectForKey:@(task)];
     }
   }];
  ELLE_TRACE("%s: background task started for transaction: %s",
             self.description.UTF8String, transaction.meta_id.UTF8String);
  [self.task_map setObject:@(task) forKey:transaction.meta_id];
}

@end
