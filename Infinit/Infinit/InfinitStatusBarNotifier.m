//
//  InfinitStatusBarNotifier.m
//  Infinit
//
//  Created by Christopher Crone on 30/04/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitStatusBarNotifier.h"

#import "JDStatusBarNotification.h"

#import <Gap/InfinitColor.h>

static InfinitStatusBarNotifier* _instance = nil;
static dispatch_once_t _instance_token = 0;

@implementation InfinitStatusBarNotifier

#pragma mark - Init

- (instancetype)init
{
  NSCAssert(_instance == nil, @"Use sharedInstance.");
  if (self = [super init])
  {
    NSString* error_id =
      [InfinitStatusBarNotifier styleIdForType:InfinitStatusBarNotificationError];
    [JDStatusBarNotification addStyleNamed:error_id
                                   prepare:^JDStatusBarStyle* (JDStatusBarStyle* style)
    {
      style.barColor = [InfinitColor colorWithRed:255 green:63 blue:58];
      style.textColor = [UIColor whiteColor];
      style.font = [UIFont fontWithName:@"HelveticaNeue-Medium" size:11.0f];
      style.animationType = JDStatusBarAnimationTypeMove;
      return style;
    }];
    NSString* info_id = [InfinitStatusBarNotifier styleIdForType:InfinitStatusBarNotificationInfo];
    [JDStatusBarNotification addStyleNamed:info_id
                                   prepare:^JDStatusBarStyle* (JDStatusBarStyle* style)
    {
      style.barColor = [InfinitColor colorWithRed:43 green:190 blue:189];
      style.textColor = [UIColor whiteColor];
      style.font = [UIFont fontWithName:@"HelveticaNeue-Medium" size:11.0f];
      style.animationType = JDStatusBarAnimationTypeMove;
      return style;
    }];
    NSString* warn_id = [InfinitStatusBarNotifier styleIdForType:InfinitStatusBarNotificationWarn];
    [JDStatusBarNotification addStyleNamed:warn_id
                                   prepare:^JDStatusBarStyle* (JDStatusBarStyle* style)
    {
      style.barColor = [InfinitColor colorWithRed:245 green:166 blue:35];
      style.textColor = [UIColor whiteColor];
      style.font = [UIFont fontWithName:@"HelveticaNeue-Medium" size:11.0f];
      style.animationType = JDStatusBarAnimationTypeMove;
      return style;
    }];
  }
  return self;
}

+ (instancetype)sharedInstance
{
  dispatch_once(&_instance_token, ^
  {
    _instance = [[InfinitStatusBarNotifier alloc] init];
  });
  return _instance;
}

#pragma mark - General

- (void)showMessage:(NSString*)message
             ofType:(InfinitStatusBarNotificationType)type
           duration:(NSTimeInterval)duration
{
  [self showMessage:message ofType:type duration:duration withActivity:NO];
}

- (void)showMessage:(NSString*)message
             ofType:(InfinitStatusBarNotificationType)type
           duration:(NSTimeInterval)duration
       withActivity:(BOOL)activity
{
  NSString* style_id = [InfinitStatusBarNotifier styleIdForType:type];
  [JDStatusBarNotification showWithStatus:message dismissAfter:duration styleName:style_id];
  if (activity)
  {
    [JDStatusBarNotification showActivityIndicator:YES
                                    indicatorStyle:UIActivityIndicatorViewStyleWhite];
  }
  else
  {
    [JDStatusBarNotification showActivityIndicator:NO
                                    indicatorStyle:UIActivityIndicatorViewStyleWhite];
  }
}

#pragma mark - Helpers

+ (NSString*)styleIdForType:(InfinitStatusBarNotificationType)type
{
  switch (type)
  {
    case InfinitStatusBarNotificationError:
      return @"InfinitStyleError";
    case InfinitStatusBarNotificationInfo:
      return @"InfinitStyleInfo";
    case InfinitStatusBarNotificationWarn:
      return @"InfinitStyleWarn";

    default:
      NSCAssert(false, @"Unknown status bar type.");
  }
}

@end
