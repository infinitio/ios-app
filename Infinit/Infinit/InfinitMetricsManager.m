//
//  InfinitMetricsManager.m
//  Infinit
//
//  Created by Christopher Crone on 19/02/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitMetricsManager.h"

#import <Gap/InfinitStateManager.h>

static InfinitMetricsManager* _instance = nil;

@implementation InfinitMetricsManager

#pragma mark - Init

- (id)init
{
  NSCAssert(_instance == nil, @"Use sharedInstance");
  if (self = [super init])
  {

  }
  return self;
}

+ (instancetype)sharedInstance
{
  if (_instance == nil)
    _instance = [[InfinitMetricsManager alloc] init];
  return _instance;
}

#pragma mark - Send Metrics

+ (void)sendMetric:(InfinitUIEvents)event
            method:(InfinitUIMethods)method
{
  [[InfinitMetricsManager sharedInstance] _sendMetric:event method:method additional:nil];
}

+ (void)sendMetric:(InfinitUIEvents)event
            method:(InfinitUIMethods)method
        additional:(NSDictionary*)additional
{
  [[InfinitMetricsManager sharedInstance] _sendMetric:event method:method additional:additional];
}

- (void)_sendMetric:(InfinitUIEvents)event
             method:(InfinitUIMethods)method
         additional:(NSDictionary*)additional
{
  [[InfinitStateManager sharedInstance] sendMetricEvent:[self event:event]
                                             withMethod:[self method:method]
                                      andAdditionalData:additional];
}

#pragma mark - Enums to Strings

- (NSString*)event:(InfinitUIEvents)event
{
  switch (event)
  {
    case InfinitUIEventAppOpen:
      return @"open app";
    case InfinitUIEventAccessContacts:
      return @"access contacts";
    case InfinitUIEventAccessGallery:
      return @"access gallery";
    case InfinitUIEventAccessNotifications:
      return @"access notifications";
    case InfinitUIEventSendGalleryViewOpen:
      return @"send gallery open";
    case InfinitUIEventSendGallerySelectedElement:
      return @"send gallery select";
    case InfinitUIEventSendRecipientViewOpen:
      return @"send recipients open";
    case InfinitUIEventSendRecipientViewToField:
      return @"send recipients to focus";
    case InfinitUIEventSendRecipientViewEmailAddress:
      return @"send recipients email";
    case InfinitUIEventSendRecipientViewSelectAddressBookContact:
      return @"send recipients contact";
    case InfinitUIEventSendRecipientViewSelectSwagger:
      return @"send recipients swagger";
    case InfinitUIEventSendRecipientViewSelectFavorite:
      return @"send recipients favorite";
    case InfinitUIEventSendRecipientViewSend:
      return @"send recipients send";
    case InfinitUIEventContactViewOpen:
      return @"contact open";
    case InfinitUIEventContactViewFavorite:
      return @"contact favorite";
    case InfinitUIEventRateFromCard:
      return @"card rating";
    case InfinitUIEventFilePreview:
      return @"preview file";
    case InfinitUIEventSMSInvite:
      return @"sms invite";

    default:
      NSCAssert(false, @"Unknown metrics event");
  }
}

- (NSString*)method:(InfinitUIMethods)method
{
  switch (method)
  {
    case InfinitUIMethodNone:
      return @"";
    case InfinitUIMethodNew:
      return @"new";
    case InfinitUIMethodRepeat:
      return @"repeat";
    case InfinitUIMethodAdd:
      return @"add";
    case InfinitUIMethodRemove:
      return @"remove";
    case InfinitUIMethodNo:
      return @"no";
    case InfinitUIMethodYes:
      return @"yes";
    case InfinitUIMethodTap:
      return @"tap";
    case InfinitUIMethodType:
      return @"type";
    case InfinitUIMethodContact:
      return @"contact";
    case InfinitUIMethodTabBar:
      return @"tab bar";
    case InfinitUIMethodSendGalleryNext:
      return @"send gallery next";
    case InfinitUIMethodExtensionFiles:
      return @"extension files";
    case InfinitUIMethodHomeCard:
      return @"home card";
    case InfinitUIMethodSent:
      return @"sent";
    case InfinitUIMethodCancel:
      return @"cancel";
    case InfinitUIMethodFail:
      return @"fail";

    default:
      NSCAssert(false, @"Unknown metrics method");
  }
}

@end
