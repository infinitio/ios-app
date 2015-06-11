//
//  InfinitMessagingRecipient.m
//  Infinit
//
//  Created by Christopher Crone on 09/06/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitMessagingRecipient.h"

#import "InfinitContactAddressBook.h"

@implementation InfinitMessagingRecipient

#pragma mark - Init

- (instancetype)initWithRecipient:(InfinitContactAddressBook*)contact
                           method:(InfinitMessageMethod)method
{
  if (self = [super init])
  {
    _method = method;
    if (self.method == InfinitMessageEmail)
    {
      if (contact.selected_email_index >= contact.emails.count)
        return nil;
      _identifier = contact.emails[contact.selected_email_index];
    }
    if (self.method == InfinitMessageNative)
    {
      if (contact.selected_phone_index >= contact.phone_numbers.count)
        return nil;
      _identifier = contact.phone_numbers[contact.selected_phone_index];
    }
    else if (self.method == InfinitMessageWhatsApp)
    {
      _identifier = @(contact.address_book_id);
    }
    if (!self.identifier)
      return nil;
  }
  return self;
}

+ (instancetype)recipient:(InfinitContactAddressBook*)contact
               withMethod:(InfinitMessageMethod)method
{
  return [[self alloc] initWithRecipient:contact method:method];
}

@end
