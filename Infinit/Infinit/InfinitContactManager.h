//
//  InfinitContactManager.h
//  Infinit
//
//  Created by Christopher Crone on 28/04/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface InfinitContactManager : NSObject

+ (instancetype)sharedInstance;

/** Inform the users that we've got access to the Address Book.
 The manager will try to upload the user's contacts if it has not already done so.
 */
- (void)gotAddressBookAccess;

/** Fetch an array of all the user's contacts.
 @return Array of InfinitContact objects or nil if no access.
 */
- (NSArray*)allContacts;

@end
