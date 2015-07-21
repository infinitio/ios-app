//
//  InfinitContactManager.h
//  Infinit
//
//  Created by Christopher Crone on 28/04/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import <Foundation/Foundation.h>

@class InfinitContactAddressBook;
@class InfinitUser;

@interface InfinitContactManager : NSObject

+ (instancetype)sharedInstance;

/** Inform the users that we've got access to the Address Book.
 The manager will try to upload the user's contacts if it has not already done so.
 */
- (void)gotAddressBookAccess;

/** Fetch an array of all the user's contacts that the device can message.
 This won't include contacts with only phone numbers on iPads.
 @return Array of InfinitContact objects or nil if no access.
 */
- (NSArray*)allContacts;

/** Determine address book contact for user.
 @param user
  InfinitUser object.
 @return address book contact.
 */
- (InfinitContactAddressBook*)contactForUser:(InfinitUser*)user;

@end
