//
//  InfinitContactAddressBook.h
//  Infinit
//
//  Created by Christopher Crone on 02/06/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitContact.h"

#import <AddressBook/AddressBook.h>

@interface InfinitContactAddressBook : InfinitContact

@property (nonatomic, readonly) int32_t address_book_id;
@property (nonatomic, readonly) NSArray* linked_address_book_ids;
@property (nonatomic, strong) NSArray* emails;
@property (nonatomic, strong) NSArray* phone_numbers;
@property (nonatomic, readwrite) NSInteger selected_email_index;
@property (nonatomic, readwrite) NSInteger selected_phone_index;

+ (instancetype)contactWithABRecord:(ABRecordRef)record;

@end
