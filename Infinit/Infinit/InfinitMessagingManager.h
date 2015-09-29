//
//  InfinitMessagingManager.h
//  Infinit
//
//  Created by Christopher Crone on 09/06/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import <Foundation/Foundation.h>

@class InfinitMessagingRecipient;

typedef NS_ENUM(NSUInteger, InfinitMessageStatus)
{
  InfinitMessageStatusSuccess,
  InfinitMessageStatusCancel,
  InfinitMessageStatusFail,
};

@interface InfinitMessagingManager : NSObject

+ (instancetype)sharedInstance;

/** Show a prefilled messaging window for a contact so that the user can send the message.
 @param message
  Message that should be prefilled.
 @param recipient
  Recipient that should receive the message.
 @param completion_block
  Block to be run on completion.
 */
typedef void(^InfinitSendMessageCompletionBlock)(InfinitMessagingRecipient* recipient,
                                                 NSString* message,
                                                 InfinitMessageStatus status);
- (void)sendMessage:(NSString*)message
        toRecipient:(InfinitMessagingRecipient*)recipient
    completionBlock:(InfinitSendMessageCompletionBlock)completion_block;

/** Show a prefilled messaging window for a contact so that the user can send the message.
 @param message
  Message that should be prefilled.
 @param subject
  Prefilled message subject. Currently only used for native emails.
 @param recipient
  Recipient that should receive the message.
 @param completion_block
  Block to be run on completion.
 */
- (void)sendMessage:(NSString*)message
        withSubject:(NSString*)subject
        toRecipient:(InfinitMessagingRecipient*)recipient
    completionBlock:(InfinitSendMessageCompletionBlock)completion_block;

@end
