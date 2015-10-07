//
//  InfinitChecklistManager.m
//  Infinit
//
//  Created by Chris Crone on 06/10/15.
//  Copyright © 2015 Infinit. All rights reserved.
//

#import "InfinitChecklistManager.h"

#import "InfinitApplicationSettings.h"
#import "InfinitChecklistViewController.h"
#import "InfinitHostDevice.h"
#import "InfinitMetricsManager.h"

#import <Gap/InfinitConnectionManager.h>

#undef check
#import <elle/log.hh>

ELLE_LOG_COMPONENT("iOS.ChecklistManager");

static InfinitChecklistManager* _instance = nil;
static dispatch_once_t _instance_token = 0;

@implementation InfinitChecklistManager

#pragma mark - Init

- (instancetype)init
{
  NSAssert(_instance == nil, @"Singleton");
  if (self = [super init])
  {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(connectionStatusChanged:)
                                                 name:INFINIT_CONNECTION_STATUS_CHANGE
                                               object:nil];
  }
  return self;
}

+ (void)start
{
  dispatch_once(&_instance_token, ^
  {
    _instance = [[self alloc] init];
  });
}

#pragma mark - Connection Handling

- (void)connectionStatusChanged:(NSNotification*)notification
{
  InfinitConnectionStatus* connection_status = notification.object;
  if (connection_status.status)
  {
    // We only want to do this once per launch so that we really count launches.
    static dispatch_once_t _connect_token = 0;
    dispatch_once(&_connect_token, ^
    {
      InfinitApplicationSettings* settings = [InfinitApplicationSettings sharedInstance];
      settings.launch_count += 1;
      ELLE_TRACE("%s: launch count: %lu", self.description.UTF8String, settings.launch_count);
      if ([InfinitHostDevice english] && settings.launch_count == 10)
      {
        ELLE_LOG("%s: show checklist after launch %lu",
                 self.description.UTF8String, settings.launch_count);
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^
        {
          UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
          UIViewController* root_controller =
            [UIApplication sharedApplication].keyWindow.rootViewController;
          if (root_controller.presentedViewController)
            root_controller = root_controller.presentedViewController;
          UINavigationController* nav_controller =
            [storyboard instantiateViewControllerWithIdentifier:@"self_quota_nav_controller"];
          [root_controller presentViewController:nav_controller animated:YES completion:NULL];
          [InfinitMetricsManager sendMetric:InfinitUIEventChecklistOpen
                                     method:InfinitUIMethodAuto];
        });
      }
    });
  }
}

@end
