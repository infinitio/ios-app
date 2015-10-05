//
//  InfinitMessagingManager.m
//  Infinit
//
//  Created by Christopher Crone on 09/06/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitMessagingManager.h"

#import "InfinitContact.h"
#import "InfinitHostDevice.h"
#import "InfinitMessagingRecipient.h"

#import <MessageUI/MessageUI.h>
#import <Gap/NSString+URLEncode.h>

#undef check
#import <elle/log.hh>

ELLE_LOG_COMPONENT("iOS.MessagingManager");

@interface InfinitMessagingManager () <MFMailComposeViewControllerDelegate,
                                       MFMessageComposeViewControllerDelegate>

@property (atomic, readwrite) InfinitMessageStatus last_status;
@property (nonatomic, readonly) dispatch_queue_t queue;
@property (nonatomic, readonly) UIViewController* main_view_controller;
@property (atomic, readwrite) dispatch_semaphore_t message_sent;
@property (atomic, readwrite) MFMailComposeViewController* native_email_controller;
@property (atomic, readwrite) MFMessageComposeViewController* native_message_controller;

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
  [self sendMessage:message withSubject:nil toRecipient:recipient completionBlock:completion_block];
}

- (void)sendMessage:(NSString*)message
        withSubject:(NSString*)subject
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
    if (recipient.method == InfinitMessageMetaEmail)
    {
      self.last_status = InfinitMessageStatusSuccess;
      dispatch_semaphore_signal(strong_self.message_sent);
    }
    else if (recipient.method == InfinitMessageNativeEmail)
    {
      if ([MFMailComposeViewController canSendMail])
      {
        strong_self.native_email_controller = [[MFMailComposeViewController alloc] init];
        strong_self.native_email_controller.toRecipients = @[recipient.identifier];
        [strong_self.native_email_controller setMessageBody:message isHTML:NO];
        strong_self.native_email_controller.subject = subject;
        strong_self.native_email_controller.mailComposeDelegate = self;
        [strong_self.main_view_controller presentViewController:strong_self.native_email_controller
                                                       animated:YES
                                                     completion:NULL];
      }
      else
      {
        NSString* mail_to = [NSString stringWithFormat:@"mailto:%@?Subject=%@&Body=%@",
                             recipient.identifier.infinit_URLEncoded,
                             subject.infinit_URLEncoded,
                             message.infinit_URLEncoded];
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:mail_to]];
      }
    }
    else if (recipient.method == InfinitMessageNativeSMS)
    {
      strong_self.native_message_controller = [[MFMessageComposeViewController alloc] init];
      strong_self.native_message_controller.recipients = @[recipient.identifier];
      strong_self.native_message_controller.body = message;
      strong_self.native_message_controller.messageComposeDelegate = strong_self;
      [strong_self.main_view_controller presentViewController:strong_self.native_message_controller
                                                     animated:YES
                                                   completion:NULL];
    }
    else if (recipient.method == InfinitMessageWhatsApp)
    {
      if ([InfinitHostDevice canSendWhatsApp])
      {
        [[NSNotificationCenter defaultCenter] addObserver:strong_self
                                                 selector:@selector(_becameActiveAfterWhatsApp:)
                                                     name:UIApplicationDidBecomeActiveNotification
                                                   object:nil];
        [strong_self _openWhatsAppForMessage:message
                           contactIdentifier:recipient.address_book_id];
      }
    }
    else
    {
      ELLE_WARN("%s: unhandled message type (%d): %s",
                self.description.UTF8String, recipient.method, recipient.method_description);
      dispatch_semaphore_signal(strong_self.message_sent);
    }
    dispatch_semaphore_wait(strong_self.message_sent, DISPATCH_TIME_FOREVER);
    completion_block(recipient, message, strong_self.last_status);
  });
}

- (void)_openWhatsAppForMessage:(NSString*)message
              contactIdentifier:(int32_t)identifier
{
  NSString* url_str = [NSString stringWithFormat:@"whatsapp://send?abid=%d&text=%@",
                       identifier, message.infinit_URLEncoded];
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

#pragma mark - MFMailComposeViewControllerDelegate

- (void)mailComposeController:(MFMailComposeViewController*)controller 
          didFinishWithResult:(MFMailComposeResult)result
                        error:(nullable NSError*)error
{
  switch (result)
  {
    case MFMailComposeResultCancelled:
    case MFMailComposeResultSaved:
      self.last_status = InfinitMessageStatusCancel;
      break;
    case MFMailComposeResultFailed:
      self.last_status = InfinitMessageStatusFail;
      break;
    case MFMailComposeResultSent:
      self.last_status = InfinitMessageStatusSuccess;
      break;
      
    default:
      break;
  }
  [self.native_email_controller dismissViewControllerAnimated:YES
                                                     completion:^
   {
     dispatch_semaphore_signal(self.message_sent);
     self.native_email_controller = nil;
   }];
}

#pragma mark - MFMessageComposeViewControllerDelegate

- (void)messageComposeViewController:(MFMessageComposeViewController*)controller
                 didFinishWithResult:(MessageComposeResult)result
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
  [self.native_message_controller dismissViewControllerAnimated:YES
                                                     completion:^
   {
     dispatch_semaphore_signal(self.message_sent);
     self.native_message_controller = nil;
   }];
}

#pragma mark - Helpers

- (UIViewController*)main_view_controller
{
  UIViewController* res = [UIApplication sharedApplication].keyWindow.rootViewController;
  if (res.presentedViewController)
    res = res.presentedViewController;
  return res;
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
