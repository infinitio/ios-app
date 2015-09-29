//
//  InfinitRatingManager.m
//  Infinit
//
//  Created by Christopher Crone on 05/02/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitRatingManager.h"

#import "InfinitApplicationSettings.h"

#import <Gap/InfinitPeerTransactionManager.h>
#import <Gap/InfinitStateManager.h>

static InfinitRatingManager* _instance = nil;
static dispatch_once_t _instance_token = 0;
static NSUInteger _required_transaction_count = 2;

@interface InfinitRatingManager ()

@property (nonatomic, weak, readonly) InfinitApplicationSettings* settings;

@end

@implementation InfinitRatingManager

#pragma mark - Init

- (id)init
{
  NSCAssert(_instance == nil, @"Use sharedInstance");
  if (self = [super init])
  {
    _settings = [InfinitApplicationSettings sharedInstance];
    _show_transaction_rating = NO;
    if (!self.settings.rated_app)
    {
      if (self.settings.rating_transactions.unsignedIntegerValue < _required_transaction_count)
      {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(transactionUpdated:)
                                                     name:INFINIT_PEER_TRANSACTION_STATUS_NOTIFICATION
                                                   object:nil];
      }
      else
      {
        _show_transaction_rating = YES;
      }
    }
  }
  return self;
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

+ (instancetype)sharedInstance
{
  dispatch_once(&_instance_token, ^
  {
    _instance = [[InfinitRatingManager alloc] init];
  });
  return _instance;
}

#pragma mark - General

- (void)doneRating
{
  _show_transaction_rating = NO;
  [InfinitApplicationSettings sharedInstance].rated_app = YES;
}

#pragma mark - Transaction Updates

- (void)transactionUpdated:(NSNotification*)notification
{
  if (self.settings.rated_app)
    return;
  NSNumber* id_ = notification.userInfo[kInfinitTransactionId];
  InfinitPeerTransaction* transaction =
    [[InfinitPeerTransactionManager sharedInstance] transactionWithId:id_];
  NSString* self_device_id = [InfinitStateManager sharedInstance].self_device_id;
  if (transaction.status == gap_transaction_finished)
  {
    if ([transaction.sender_device_id isEqualToString:self_device_id] ||
        transaction.recipient.is_self)
    {
      NSUInteger rating_transactions = self.settings.rating_transactions.unsignedIntegerValue;
      self.settings.rating_transactions = @(++rating_transactions);
      if (rating_transactions >= _required_transaction_count)
      {
        _show_transaction_rating = YES;
        [[NSNotificationCenter defaultCenter] removeObserver:self];
      }
    }
  }
}

@end
