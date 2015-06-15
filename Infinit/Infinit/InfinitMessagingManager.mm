//
//  InfinitMessagingManager.m
//  Infinit
//
//  Created by Christopher Crone on 09/06/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitMessagingManager.h"

#import "AppDelegate.h"
#import "InfinitContact.h"
#import "InfinitHostDevice.h"
#import "InfinitMessagingRecipient.h"

#import <MessageUI/MessageUI.h>

#undef check
#import <elle/log.hh>

ELLE_LOG_COMPONENT("iOS.MessagingManager");

@interface InfinitMessagingManager () <MFMessageComposeViewControllerDelegate>

@property (atomic, readwrite) InfinitMessageStatus last_status;
@property (nonatomic, readonly) dispatch_queue_t queue;
@property (nonatomic, readonly) UIViewController* main_view_controller;
@property (atomic, readwrite) dispatch_semaphore_t message_sent;
@property (atomic, readwrite) MFMessageComposeViewController* sms_controller;

@end

static InfinitMessagingManager* _instance = nil;
static dispatch_once_t _instance_token = 0;

@implementation InfinitMessagingManager

#pragma mark - Init

- (instancetype)init
{
  NSCAssert(_instance == nil, @"Use sharedInstance.");
  if (self = [super init])
  {
    _queue = dispatch_queue_create("io.Infinit.MessageQueue", DISPATCH_QUEUE_SERIAL);
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
    _instance = [[self alloc] init];
  });
  return _instance;
}

#pragma mark - Messaging

- (void)sendMessage:(NSString*)message
        toRecipient:(InfinitMessagingRecipient*)recipient
    completionBlock:(InfinitSendMessageCompletionBlock)completion_block
{
  __weak InfinitMessagingManager* weak_self = self;
  dispatch_async(self.queue, ^
  {
    if (!weak_self)
      return;
    InfinitMessagingManager* strong_self = weak_self;
    strong_self.message_sent = dispatch_semaphore_create(0);
    if (recipient.method == InfinitMessageEmail)
    {
      completion_block(recipient, message, InfinitMessageStatusSuccess);
      dispatch_semaphore_signal(strong_self.message_sent);
    }
    else if (recipient.method == InfinitMessageNative)
    {
      strong_self.sms_controller = [[MFMessageComposeViewController alloc] init];
      strong_self.sms_controller.recipients = @[recipient.identifier];
      strong_self.sms_controller.body = message;
      strong_self.sms_controller.messageComposeDelegate = strong_self;
      [strong_self.main_view_controller presentViewController:strong_self.sms_controller
                                                     animated:YES
                                                   completion:NULL];
    }
    else if (recipient.method == InfinitMessageWhatsApp)
    {
      [[NSNotificationCenter defaultCenter] addObserver:strong_self
                                               selector:@selector(_becameActiveAfterWhatsApp:)
                                                   name:UIApplicationDidBecomeActiveNotification
                                                 object:nil];
      if ([InfinitHostDevice canSendWhatsApp])
      {
        [strong_self _openWhatsAppForMessage:message
                           contactIdentifier:recipient.address_book_id];
      }
    }
    dispatch_semaphore_wait(strong_self.message_sent, DISPATCH_TIME_FOREVER);
    completion_block(recipient, message, strong_self.last_status);
  });
}

- (void)_openWhatsAppForMessage:(NSString*)message_
              contactIdentifier:(int32_t)identifier
{
  NSString* message = [message_ stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
  NSString* url_str =
    [NSString stringWithFormat:@"whatsapp://send?abid=%d&text=%@", identifier, message];
  NSURL* url = [NSURL URLWithString:url_str];
  [[UIApplication sharedApplication] openURL:url];
}

#pragma mark - Became Active

- (void)_becameActiveAfterWhatsApp:(NSNotification*)notification
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  self.last_status = InfinitMessageStatusSuccess;
  dispatch_semaphore_signal(self.message_sent);
}

#pragma mark - MFMessageComposeViewControllerDelegate

- (void)_handleResult:(MessageComposeResult)result
{
  switch (result)
  {
    case MessageComposeResultCancelled:
      self.last_status = InfinitMessageStatusCancel;
      break;
    case MessageComposeResultFailed:
      self.last_status = InfinitMessageStatusFail;
      break;
    case MessageComposeResultSent:
      self.last_status = InfinitMessageStatusSuccess;
      break;

    default:
      break;
  }
  [self.sms_controller dismissViewControllerAnimated:YES
                                          completion:^
  {
    dispatch_semaphore_signal(self.message_sent);
    self.sms_controller = nil;
  }];
}

- (void)messageComposeViewController:(MFMessageComposeViewController*)controller
                 didFinishWithResult:(MessageComposeResult)result
{
  [self _handleResult:result];
}

#pragma mark - Helpers

- (UIViewController*)main_view_controller
{
  return ((AppDelegate*)[UIApplication sharedApplication].delegate).root_controller;
}

- (NSString*)stringFromStatus:(InfinitMessageStatus)status
{
  switch (status)
  {
    case InfinitMessageStatusCancel:
      return @"cancel";
    case InfinitMessageStatusFail:
      return @"fail";
    case InfinitMessageStatusSuccess:
      return @"succes";

    default:
      return @"unknown";
  }
}

@end
