//
//  InfinitContact.m
//  Infinit
//
//  Created by Christopher Crone on 12/01/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitContact.h"

@implementation InfinitContact
{
@private
  BOOL _inited_with_addressbook;
}

#pragma mark Init

- (id)initWithABRecord:(ABRecordRef)record
{
  if (self = [super init])
  {
    _inited_with_addressbook = YES;
    NSData* image_data =
      (__bridge NSData*)(ABPersonCopyImageDataWithFormat(record, kABPersonImageFormatThumbnail));
    _avatar = [UIImage imageWithData:image_data scale:1.0f];

    ABMultiValueRef email_property = ABRecordCopyValue(record, kABPersonEmailProperty);
    _emails = (__bridge NSArray*)ABMultiValueCopyArrayOfAllValues(email_property);
    CFRelease(email_property);

    NSString* first_name = (__bridge NSString*)ABRecordCopyValue(record, kABPersonFirstNameProperty);
    NSString* surname = (__bridge NSString*)ABRecordCopyValue(record, kABPersonLastNameProperty);
    _fullname = [NSString stringWithFormat:@"%@ %@", first_name, surname];

    _infinit_user = nil;

    ABMultiValueRef phone_property = ABRecordCopyValue(record, kABPersonPhoneProperty);
    _phone_numbers = (__bridge NSArray*)ABMultiValueCopyArrayOfAllValues(phone_property);
    CFRelease(phone_property);
  }
  return self;
}

- (id)initWithInfinitUser:(InfinitUser*)user
{
  if (self = [super init])
  {
    _inited_with_addressbook = NO;
    _infinit_user = user;
    _avatar = user.avatar;
    _emails = nil;
    _fullname = user.fullname;
    _phone_numbers = nil;
  }
  return self;
}

#pragma mark General

- (void)addInfinitUser:(InfinitUser*)user
{
  if (!_inited_with_addressbook)
    return;
  _infinit_user = user;
}

#pragma mark Helpers

- (NSString*)description
{
  return [NSString stringWithFormat:@"<%@> emails: %@\rnumbers: %@\rinfinit:%@",
          self.fullname, self.emails, self.phone_numbers, self.infinit_user];
}

@end
