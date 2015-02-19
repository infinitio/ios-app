//
//  InfinitBackgroundTask.m
//  Infinit
//
//  Created by Christopher Crone on 17/02/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitBackgroundTask.h"

#undef check
#import <elle/log.hh>

ELLE_LOG_COMPONENT("iOS.BackgroundTask");

@interface InfinitBackgroundTask ()

@property (nonatomic, weak, readonly) id<InfinitBackgroundTaskProtocol> delegate;
@property (nonatomic, readwrite) NSTimer* wait_timer;

@end

@implementation InfinitBackgroundTask

#pragma mark - Init

- (id)initBackgroundTaskType:(InfinitBackgroundTaskTypes)type
            forTransactionId:(NSNumber*)transaction_id
                withDelegate:(id<InfinitBackgroundTaskProtocol>)delegate
{
  if (self = [super init])
  {
    _delegate = delegate;
    _type = type;
    _transaction_id = transaction_id;
    _task_id = [[UIApplication sharedApplication] beginBackgroundTaskWithName:self.description
                                                   expirationHandler:^
    {
      [self.delegate backgroundTaskAboutToBeKilled:self];
      ELLE_LOG("%s: killed by the OS", self.description.UTF8String);
      [self.delegate backgroundTaskEnded:self];
    }];
    ELLE_TRACE("%s: started", self.description.UTF8String);
  }
  return self;
}

+ (instancetype)waitTaskforTransactionId:(NSNumber*)transaction_id
                        forTimeInSeconds:(NSTimeInterval)duration
                            withDelegate:(id<InfinitBackgroundTaskProtocol>)delegate
{
  InfinitBackgroundTask* res =
    [[InfinitBackgroundTask alloc] initBackgroundTaskType:InfinitBackgroundTaskWait
                                         forTransactionId:transaction_id
                                             withDelegate:delegate];
  res.wait_timer = [NSTimer timerWithTimeInterval:duration
                                           target:res
                                         selector:@selector(endTask)
                                         userInfo:nil
                                          repeats:NO];
  [[NSRunLoop mainRunLoop] addTimer:res.wait_timer forMode:NSDefaultRunLoopMode];
  return res;
}

+ (instancetype)transferTaskforTransactionId:(NSNumber*)transaction_id
                                withDelegate:(id<InfinitBackgroundTaskProtocol>)delegate
{
  return [[InfinitBackgroundTask alloc] initBackgroundTaskType:InfinitBackgroundTaskTransferring
                                              forTransactionId:transaction_id
                                                  withDelegate:delegate];
}

- (void)dealloc
{
  if (self.wait_timer && self.wait_timer.valid)
  {
    [self.wait_timer invalidate];
    _wait_timer = nil;
  }
}

#pragma mark - Change Type

- (void)changeWaitingToTransferring
{
  ELLE_TRACE("%s: change waiting to transferring", self.description.UTF8String);
  if (self.type != InfinitBackgroundTaskWait)
    return;
  if (self.wait_timer && self.wait_timer.valid)
    [self.wait_timer invalidate];
  _wait_timer = nil;
  _type = InfinitBackgroundTaskTransferring;
}

#pragma mark - End

- (void)endTask
{
  if (self.wait_timer && self.wait_timer.valid)
  {
    [self.wait_timer invalidate];
    _wait_timer = nil;
  }
  if (self.task_id != UIBackgroundTaskInvalid)
  {
    ELLE_TRACE("%s: ending", self.description.UTF8String);
    [[UIApplication sharedApplication] endBackgroundTask:self.task_id];
    _task_id = UIBackgroundTaskInvalid;
  }
  [self.delegate backgroundTaskEnded:self];
}

#pragma mark - Description

- (NSString*)taskTypeString
{
  switch (self.type)
  {
    case InfinitBackgroundTaskTransferring:
      return @"transfer task";
    case InfinitBackgroundTaskWait:
      return @"wait task";

    default:
      return @"unknown task";
  }
}

- (NSString*)description
{
  return [NSString stringWithFormat:@"%@ for transaction(%@)",
          [self taskTypeString], self.transaction_id];
}

@end
