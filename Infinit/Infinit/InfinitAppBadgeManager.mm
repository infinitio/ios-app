//
//  InfinitAppBadgeManager.m
//  Infinit
//
//  Created by Chris Crone on 21/09/15.
//  Copyright © 2015 Infinit. All rights reserved.
//

#import "InfinitAppBadgeManager.h"
#import "AppDelegate.h"

#import <Gap/InfinitConnectionManager.h>
#import <Gap/InfinitPeerTransactionManager.h>

#undef check
#import <elle/log.hh>

ELLE_LOG_COMPONENT("iOS.AppBadgeManager");

@interface InfinitAppBadgeManager ()

@property (nonatomic) NSInteger badge;

@end

static dispatch_once_t _instance_token = 0;
static InfinitAppBadgeManager* _instance;

@implementation InfinitAppBadgeManager

#pragma mark - Init

- (instancetype)init
{
  if (self = [super init])
  {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationWillResignActive:)
                                                 name:UIApplicationWillResignActiveNotification 
                                               object:nil];
  }
  return self;
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Callbacks

- (void)applicationWillResignActive:(UIApplication*)application
{
  if (![InfinitConnectionManager sharedInstance].connected)
    return;
  self.badge = [InfinitPeerTransactionManager sharedInstance].receivable_transaction_count;
}

#pragma mark - Badge handling

- (void)setBadge:(NSInteger)badge
{
  ELLE_TRACE("%s: set application badge to: %d", self.description.UTF8String, badge);
  [UIApplication sharedApplication].applicationIconBadgeNumber = badge;
}

#pragma mark - External

+ (void)startManager
{
  dispatch_once(&_instance_token, ^
  {
    _instance = [[self alloc] init];
  });
}

@end
