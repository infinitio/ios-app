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
#import <Gap/InfinitUserManager.h>
#import <Gap/NSString+email.h>
#import <Gap/NSString+PhoneNumber.h>

@import AddressBook;

@interface InfinitContactManager ()

@property (atomic, readonly) NSArray* all_contacts;

@end

static InfinitContactManager* _instance = nil;
static dispatch_once_t _instance_token = 0;
static dispatch_once_t _got_access_token = 0;

@implementation InfinitContactManager

- (instancetype)init
{
  NSCAssert(_instance == nil, @"Use sharedInstance.");
  if (self = [super init])
  {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(newUser:)
                                                 name:INFINIT_NEW_USER_NOTIFICATION 
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(clearModel)
                                                 name:INFINIT_CLEAR_MODEL_NOTIFICATION 
                                               object:nil];
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

- (void)clearModel
{
  _got_access_token = 0;
}

#pragma mark - Public

- (void)fetchContacts
{
  if (ABAddressBookGetAuthorizationStatus() != kABAuthorizationStatusAuthorized)
    return;
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
  NSSortDescriptor* sort =
    [[NSSortDescriptor alloc] initWithKey:@"fullname"
                                ascending:YES
                                 selector:@selector(caseInsensitiveCompare:)];
  [res sortUsingDescriptors:@[sort]];
  _all_contacts = [res copy];
}

- (void)gotAddressBookAccess
{
  if (ABAddressBookGetAuthorizationStatus() != kABAuthorizationStatusAuthorized)
    return;
  dispatch_once(&_got_access_token, ^
  {
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
      [[InfinitContactManager sharedInstance] fetchGhostData];
      [[InfinitStateManager sharedInstance] uploadContacts:upload_array
                                           completionBlock:^(InfinitStateResult* result)
      {
        if (result.success)
          [InfinitApplicationSettings sharedInstance].address_book_uploaded = YES;
      }];
    });
  });
}

- (void)fetchGhostData
{
  if (ABAddressBookGetAuthorizationStatus() != kABAuthorizationStatusAuthorized)
    return;
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^
  {
    if (!self.all_contacts)
      [self fetchContacts];
    NSMutableArray* ghosts = [NSMutableArray array];
    NSArray* swaggers = [InfinitUserManager sharedInstance].alphabetical_swaggers;
    for (InfinitUser* user in swaggers)
    {
      if (user.ghost)
        [ghosts addObject:user];
    }
    if (ghosts.count == 0)
      return;
    for (InfinitUser* ghost in ghosts)
    {
      [self tryUpdateGhost:ghost];
    }
  });
}

#pragma mark - New User

- (void)newUser:(NSNotification*)notification
{
  if (ABAddressBookGetAuthorizationStatus() != kABAuthorizationStatusAuthorized)
    return;
  if (_got_access_token == 0)
    return;
  NSNumber* user_id = notification.userInfo[kInfinitUserId];
  InfinitUser* user = [[InfinitUserManager sharedInstance] userWithId:user_id];
  if (!user.ghost)
    return;
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^
  {
    [self tryUpdateGhost:user];
  });
}

#pragma mark - Helpers

- (NSDictionary*)dictForContact:(InfinitContact*)contact
{
  NSArray* email_addresses = contact.emails ? contact.emails : @[];
  NSArray* phone_numbers = contact.phone_numbers ? contact.phone_numbers : @[];
  return @{@"email_addresses": email_addresses, @"phone_numbers": phone_numbers};
}

- (NSString*)strippedNumber:(NSString*)number
{
  return [number stringByReplacingOccurrencesOfString:@"[^0-9]"
                                           withString:@""
                                              options:NSRegularExpressionSearch
                                                range:NSMakeRange(0, number.length)];
}

- (void)tryUpdateGhost:(InfinitUser*)ghost
{
  NSString* email = nil;
  NSString* phone = nil;
  if (ghost.fullname.infinit_isEmail)
  {
    email = ghost.fullname;
  }
  else if (ghost.fullname.infinit_isPhoneNumber)
  {
    phone = [self strippedNumber:ghost.fullname];
  }
  if (!email && !phone)
    return;
  for (InfinitContact* contact in self.all_contacts)
  {
    BOOL found = NO;
    if (contact.emails.count && [contact.emails containsObject:email])
    {
      [ghost updateGhostWithFullname:contact.fullname avatar:contact.avatar];
      found = YES;
    }
    else if (contact.phone_numbers.count)
    {
      for (NSString* contact_phone in contact.phone_numbers)
      {
        NSString* stripped_number = [self strippedNumber:contact_phone];
        if ([stripped_number isEqualToString:phone])
        {
          found = YES;
          [ghost updateGhostWithFullname:contact.fullname avatar:contact.avatar];
          break;
        }
      }
    }
    if (found)
      break;
  }
}

@end
