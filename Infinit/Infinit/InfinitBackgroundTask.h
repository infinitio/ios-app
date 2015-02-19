//
//  InfinitBackgroundTask.h
//  Infinit
//
//  Created by Christopher Crone on 17/02/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIApplication.h>

typedef NS_ENUM(NSUInteger, InfinitBackgroundTaskTypes)
{
  InfinitBackgroundTaskWait,
  InfinitBackgroundTaskTransferring,
};

@protocol InfinitBackgroundTaskProtocol;
@interface InfinitBackgroundTask : NSObject

@property (nonatomic, readonly) UIBackgroundTaskIdentifier task_id;
@property (nonatomic, readonly) NSNumber* transaction_id;
@property (nonatomic, readonly) InfinitBackgroundTaskTypes type;

/** Starts a background task of which runs for a limited amount of time. The duration is the
 maximum amount of time the task will run for as it may be killed by the OS.
 @param transaction_id
  Transaction ID that is task is being run for.
 @param duration
  Maximum length of time that this task should be run for.
 @param delegate
  Delegate keeping track of running tasks.
 */
+ (instancetype)waitTaskforTransactionId:(NSNumber*)transaction_id
                        forTimeInSeconds:(NSTimeInterval)duration
                            withDelegate:(id<InfinitBackgroundTaskProtocol>)delegate;

/** Starts a background task which runs indefinitely (or until killed by the OS).
 @param transaction_id
  Transaction ID that is task is being run for.
 @param delegate
  Delegate keeping track of running tasks.
 */
+ (instancetype)transferTaskforTransactionId:(NSNumber*)transaction_id
                                withDelegate:(id<InfinitBackgroundTaskProtocol>)delegate;

- (void)changeWaitingToTransferring;
- (void)endTask;

@end

@protocol InfinitBackgroundTaskProtocol <NSObject>

- (void)backgroundTaskEnded:(InfinitBackgroundTask*)sender;
- (void)backgroundTaskAboutToBeKilled:(InfinitBackgroundTask*)sender;

@end
