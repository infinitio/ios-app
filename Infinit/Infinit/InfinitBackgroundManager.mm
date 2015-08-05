//
//  InfinitBackgroundManager.m
//  Infinit
//
//  Created by Christopher Crone on 30/01/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitBackgroundManager.h"

#import "InfinitBackgroundTask.h"
#import "InfinitLocalNotificationManager.h"

#import <Gap/InfinitPeerTransactionManager.h>
#import <Gap/InfinitStateManager.h>
#import <Gap/InfinitThreadSafeDictionary.h>

#import <UIKit/UIKit.h>

#undef check
#import <elle/log.hh>

ELLE_LOG_COMPONENT("iOS.BackgroundManager");

@interface InfinitBackgroundManager () <InfinitBackgroundTaskProtocol>

@property (nonatomic, readonly) InfinitThreadSafeDictionary* task_map;

@end

static InfinitBackgroundManager* _instance = nil;
static dispatch_once_t _instance_token = 0;

@implementation InfinitBackgroundManager

#pragma mark - Init

- (id)init
{
  NSCAssert(_instance == nil, @"Use sharedInstance");
  if (self = [super init])
  {
    _task_map = [InfinitThreadSafeDictionary dictionaryWithName:@"io.Infinit.BackgroundManager"
                                                 withNilSupport:NO];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(transactionUpdated:)
                                                 name:INFINIT_PEER_TRANSACTION_STATUS_NOTIFICATION 
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(clearModel)
                                                 name:INFINIT_CLEAR_MODEL_NOTIFICATION
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(stopBackgroundTasks)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:[UIApplication sharedApplication]];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(refreshBackgroundTasks)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:[UIApplication sharedApplication]];
  }
  return self;
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [self stopBackgroundTasks];
}

+ (instancetype)sharedInstance
{
  dispatch_once(&_instance_token, ^
  {
    _instance = [[InfinitBackgroundManager alloc] init];
  });
  return _instance;
}

- (void)stopBackgroundTasks
{
  for (InfinitBackgroundTask* task in self.task_map.allValues)
    [task endTask];
}

- (void)refreshBackgroundTasks
{
  [self stopBackgroundTasks];
  NSArray* transactions = [InfinitPeerTransactionManager sharedInstance].transactions;
  for (InfinitPeerTransaction* transaction in transactions)
  {
    if (transaction.from_device &&
        (transaction.status == gap_transaction_waiting_accept ||
         transaction.status == gap_transaction_new))
    {
      [self addWaitTaskForTransaction:transaction];
    }
    else if (transaction.status == gap_transaction_connecting ||
             transaction.status == gap_transaction_transferring)
    {
      [self addTransferTaskForTransaction:transaction];
    }
  }
}

- (void)clearModel
{
  [self stopBackgroundTasks];
  _instance_token = 0;
  _instance = nil;
}

#pragma mark - Transaction Updated

- (void)transactionUpdated:(NSNotification*)notification
{
  NSNumber* id_ = notification.userInfo[kInfinitTransactionId];
  InfinitPeerTransaction* transaction =
    [[InfinitPeerTransactionManager sharedInstance] transactionWithId:id_];
  InfinitBackgroundTask* existing = [self.task_map objectForKey:transaction.id_];
  if (!existing)
    return;

  if ([self shouldWaitTransactionInBackground:transaction])
  {
    // We already have a task, do nothing.
  }
  else if ([self shouldRunTransactionInBackground:transaction])
  {
    if (existing.type == InfinitBackgroundTaskWait)
    {
      ELLE_TRACE("%s: change existing task for transaction to transferring: %s",
                 self.description.UTF8String, transaction.id_.stringValue.UTF8String);
      [existing changeWaitingToTransferring];
    }
    else if (existing.type == InfinitBackgroundTaskTransferring)
    {
      // We already have a task, do nothing.
    }
  }
  else
  {
    [existing endTask];
  }
}

#pragma mark - Helpers

- (BOOL)shouldWaitTransactionInBackground:(InfinitPeerTransaction*)transaction
{
  switch (transaction.status)
  {
    case gap_transaction_new:
    case gap_transaction_waiting_accept:
      return YES;

    default:
      return NO;
  }
}

- (BOOL)shouldRunTransactionInBackground:(InfinitPeerTransaction*)transaction
{
  switch (transaction.status)
  {
    case gap_transaction_connecting:
    case gap_transaction_transferring:
      return YES;

    default:
      return NO;
  }
}

- (void)addWaitTaskForTransaction:(InfinitPeerTransaction*)transaction
{
  if ([self.task_map objectForKey:transaction.id_])
    return;
  InfinitBackgroundTask* task = [InfinitBackgroundTask waitTaskforTransactionId:transaction.id_
                                                               forTimeInSeconds:120.0f
                                                                   withDelegate:self];
  [self.task_map setObject:task forKey:transaction.id_];
}

- (void)addTransferTaskForTransaction:(InfinitPeerTransaction*)transaction
{
  if ([self.task_map objectForKey:transaction.id_])
    return;
  InfinitBackgroundTask* task =
    [InfinitBackgroundTask transferTaskforTransactionId:transaction.id_ withDelegate:self];
  [self.task_map setObject:task forKey:transaction.id_];
}

#pragma mark - Background Task Delegate

- (void)backgroundTaskAboutToBeKilled:(InfinitBackgroundTask*)sender
{
  ELLE_DEBUG("%s: background task for transaction (%s) about to be killed",
             self.description.UTF8String, sender.transaction_id);
  InfinitPeerTransaction* transaction =
    [[InfinitPeerTransactionManager sharedInstance] transactionWithId:sender.transaction_id];
  InfinitLocalNotificationManager* notifier = [InfinitLocalNotificationManager sharedInstance];
  [notifier backgroundTaskAboutToBeKilledForTransaction:transaction];
}

- (void)backgroundTaskEnded:(InfinitBackgroundTask*)sender
{
  ELLE_DEBUG("%s: remove task for transaction (%s)",
             self.description.UTF8String, sender.transaction_id.stringValue.UTF8String);
  [self.task_map removeObjectForKey:sender.transaction_id];
}

- (void)backgroundTaskTimedOut:(InfinitBackgroundTask*)sender
{
  if ([UIApplication sharedApplication].applicationState != UIApplicationStateBackground)
    return;
  InfinitPeerTransaction* transaction =
    [[InfinitPeerTransactionManager sharedInstance] transactionWithId:sender.transaction_id];
  InfinitLocalNotificationManager* notifier = [InfinitLocalNotificationManager sharedInstance];
  [notifier backgroundTaskAboutToBeKilledForTransaction:transaction];
}

@end
