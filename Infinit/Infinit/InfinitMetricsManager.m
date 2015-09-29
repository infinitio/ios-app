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
static dispatch_once_t _instance_token = 0;

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
  dispatch_once(&_instance_token, ^
  {
    _instance = [[InfinitMetricsManager alloc] init];
  });
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

+ (void)sendMetricGhostSMSSent:(BOOL)success
                          code:(NSString*)code
                    failReason:(NSString*)fail_reason
{
  [[InfinitStateManager sharedInstance] sendMetricGhostSMSSent:success
                                                          code:[code copy]
                                                    failReason:fail_reason];
}

+ (void)sendMetricGhostReminder:(BOOL)success
                         method:(gap_InviteMessageMethod)method
                           code:(NSString*)code
                     failReason:(NSString*)fail_reason
{
  [[InfinitStateManager sharedInstance] sendMetricGhostReminderSent:success
                                                             method:method
                                                               code:code
                                                         failReason:fail_reason];
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
    case InfinitUIEventExperienceCard:
      return @"card experience";
    case InfinitUIEventRateFromCard:
      return @"card rating";
    case InfinitUIEventFilePreview:
      return @"preview file";
    case InfinitUIEventGotLinkCode:
      return @"got link code";
    case InfinitUIEventAttribution:
      return @"attribution";
    case InfinitUIEventExtensionCancel:
      return @"cancel extension";
    case InfinitUIEventFeedbackOpen:
      return @"feedback open";
    case InfinitUIEventHelpOpen:
      return @"help open";

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
    case InfinitUIMethodInvalid:
      return @"invalid";
    case InfinitUIMethodValid:
      return @"valid";
    case InfinitUIMethodPadMain:
      return @"pad main";
    case InfinitUIMethodFiles:
      return @"files";
    case InfinitUIMethodFail:
      return @"fail";
    case InfinitUIMethodSuccess:
      return @"success";
    case InfinitUIMethodPositive:
      return @"positive";
    case InfinitUIMethodNegative:
      return @"negative";
    case InfinitUIMethodSettingsMenu:
      return @"settings menu";

    default:
      NSCAssert(false, @"Unknown metrics method");
  }
}

@end
