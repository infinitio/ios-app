//
//  InfinitBackgroundManager.m
//  Infinit
//
//  Created by Christopher Crone on 30/01/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitBackgroundManager.h"

#import "InfinitBackgroundTask.h"

#import <Gap/InfinitPeerTransactionManager.h>
#import <Gap/InfinitStateManager.h>

#import <UIKit/UIKit.h>

#undef check
#import <elle/log.hh>

ELLE_LOG_COMPONENT("iOS.BackgroundManager");

@interface InfinitBackgroundManager () <InfinitBackgroundTaskProtocol>

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
                                             selector:@selector(transactionAdded:)
                                                 name:INFINIT_NEW_PEER_TRANSACTION_NOTIFICATION
                                               object:nil];
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
    if (transaction.from_device && transaction.status == gap_transaction_waiting_accept)
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

- (void)transactionAdded:(NSNotification*)notification
{
  NSNumber* id_ = notification.userInfo[@"id"];
  InfinitPeerTransaction* transaction =
    [[InfinitPeerTransactionManager sharedInstance] transactionWithId:id_];
  if (transaction.from_device && transaction.status == gap_transaction_new)
    [self addWaitTaskForTransaction:transaction];
}

- (void)transactionUpdated:(NSNotification*)notification
{
  NSNumber* id_ = notification.userInfo[@"id"];
  InfinitPeerTransaction* transaction =
    [[InfinitPeerTransactionManager sharedInstance] transactionWithId:id_];
  if (transaction.from_device && transaction.status == gap_transaction_waiting_accept)
  {
    [self addWaitTaskForTransaction:transaction];
  }
  else if ([self shouldRunTransactionInBackground:transaction])
  {
    [self addTransferTaskForTransaction:transaction];
  }
  else
  {
    InfinitBackgroundTask* task = [self.task_map objectForKey:transaction.id_];
    if (task)
      [task endTask];
  }
}

#pragma mark - Helpers

- (BOOL)shouldRunTransactionInBackground:(InfinitPeerTransaction*)transaction
{
  if (transaction.done)
    return NO;
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
  if (self.task_map == nil)
    _task_map = [NSMutableDictionary dictionary];
  if ([self.task_map objectForKey:transaction.id_])
    return;
  InfinitBackgroundTask* task = [InfinitBackgroundTask waitTaskforTransactionId:transaction.id_
                                                               forTimeInSeconds:120.0f
                                                                   withDelegate:self];
  [self.task_map setObject:task forKey:transaction.id_];
}

- (void)addTransferTaskForTransaction:(InfinitPeerTransaction*)transaction
{
  if (self.task_map == nil)
    _task_map = [NSMutableDictionary dictionary];
  if ([self.task_map objectForKey:transaction.id_])
  {
    InfinitBackgroundTask* existing = [self.task_map objectForKey:transaction.id_];
    if (existing.type == InfinitBackgroundTaskWait)
    {
      ELLE_TRACE("%s: change existing task for transaction to transferring: %s",
                 self.description.UTF8String, transaction.id_.stringValue.UTF8String);
      [existing changeWaitingToTransferring];
    }
    else if (existing.type == InfinitBackgroundTaskTransferring)
    {
      return;
    }
  }
  InfinitBackgroundTask* task =
    [InfinitBackgroundTask transferTaskforTransactionId:transaction.id_ withDelegate:self];
  [self.task_map setObject:task forKey:transaction.id_];
}

#pragma mark - Background Task Delegate

- (void)backgroundTaskEnded:(InfinitBackgroundTask*)sender
{
  ELLE_DEBUG("%s: remove task for transaction (%s)",
             self.description.UTF8String, sender.transaction_id.stringValue.UTF8String);
  [self.task_map removeObjectForKey:sender.transaction_id];
}

@end
