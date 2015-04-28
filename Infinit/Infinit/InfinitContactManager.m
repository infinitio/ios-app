//
//  InfinitContactManager.m
//  Infinit
//
//  Created by Christopher Crone on 28/04/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitContactManager.h"

#import "InfinitApplicationSettings.h"
#import "InfinitContact.h"

#import <Gap/InfinitStateManager.h>

@import AddressBook;

@interface InfinitContactManager ()

@property (atomic, readonly) NSArray* all_contacts;
@property (atomic, readonly) BOOL uploading;

@end

static InfinitContactManager* _instance = nil;
static dispatch_once_t _instance_token = 0;

@implementation InfinitContactManager

- (instancetype)init
{
  NSCAssert(_instance == nil, @"Use sharedInstance.");
  if (self = [super init])
  {
  }
  return self;
}

+ (instancetype)sharedInstance
{
  dispatch_once(&_instance_token, ^
  {
    _instance = [[InfinitContactManager alloc] init];
  });
  return _instance;
}

#pragma mark - Public

- (void)fetchContacts
{
  if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized)
  {
    CFErrorRef* error = nil;
    ABAddressBookRef address_book = ABAddressBookCreateWithOptions(NULL, error);
    NSMutableArray* res = [NSMutableArray array];
    CFArrayRef sources = ABAddressBookCopyArrayOfAllSources(address_book);
    for (int i = 0; i < CFArrayGetCount(sources); i++)
    {
      ABRecordRef source = CFArrayGetValueAtIndex(sources, i);
      CFArrayRef contacts =
        ABAddressBookCopyArrayOfAllPeopleInSourceWithSortOrdering(address_book,
                                                                  source,
                                                                  kABPersonSortByFirstName);
      for (int j = 0; j < CFArrayGetCount(contacts); j++)
      {
        ABRecordRef person = CFArrayGetValueAtIndex(contacts, j);
        if (person)
        {
          InfinitContact* contact = [[InfinitContact alloc] initWithABRecord:person];
          if (contact != nil && (contact.emails.count > 0 || (contact.phone_numbers.count > 0)))
          {
            [res addObject:contact];
          }
        }
      }
      CFRelease(contacts);
    }
    CFRelease(sources);
    CFRelease(address_book);
    NSSortDescriptor* sort = [[NSSortDescriptor alloc] initWithKey:@"fullname"
                                                         ascending:YES
                                                          selector:@selector(caseInsensitiveCompare:)];
    [res sortUsingDescriptors:@[sort]];
    _all_contacts = [res copy];
  }
}

- (void)uploadContacts
{
  if (ABAddressBookGetAuthorizationStatus() != kABAuthorizationStatusAuthorized)
    return;
  if ([InfinitApplicationSettings sharedInstance].address_book_uploaded || self.uploading)
    return;
  _uploading = YES;
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^
  {
    [self fetchContacts];
    NSMutableArray* upload_array = [NSMutableArray array];
    [self.all_contacts enumerateObjectsUsingBlock:^(InfinitContact* contact,
                                                    NSUInteger i, 
                                                    BOOL* stop)
    {
      [upload_array addObject:[self dictForContact:contact]];
    }];
    [[InfinitStateManager sharedInstance] uploadContacts:upload_array
                                         completionBlock:^(InfinitStateResult* result)
    {
      if (result.success)
        [InfinitApplicationSettings sharedInstance].address_book_uploaded = YES;
      _uploading = NO;
    }];
  });
}

#pragma mark - Helpers

- (NSDictionary*)dictForContact:(InfinitContact*)contact
{
  NSArray* email_addresses = contact.emails ? contact.emails : @[];
  NSArray* phone_numbers = contact.phone_numbers ? contact.phone_numbers : @[];
  return @{@"email_addresses": email_addresses, @"phone_numbers": phone_numbers};
}

@end
