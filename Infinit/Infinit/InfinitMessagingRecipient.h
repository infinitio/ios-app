//
//  InfinitMessagingRecipient.h
//  Infinit
//
//  Created by Christopher Crone on 09/06/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, InfinitMessageMethod)
{
  InfinitMessageEmail,
  InfinitMessageNative,
  InfinitMessageWhatsApp,
};

@class InfinitContactAddressBook;

@interface InfinitMessagingRecipient : NSObject

@property (nonatomic, readonly) int32_t address_book_id;
@property (nonatomic, readonly) id identifier;
@property (nonatomic, readonly) InfinitMessageMethod method;
@property (nonatomic, readonly) NSString* name;

+ (instancetype)recipient:(InfinitContactAddressBook*)contact
               withMethod:(InfinitMessageMethod)method;

@end
