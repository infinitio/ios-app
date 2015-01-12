//
//  InfinitContact.h
//  Infinit
//
//  Created by Christopher Crone on 12/01/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AddressBook/AddressBook.h>

#import <Gap/InfinitUser.h>

@interface InfinitContact : NSObject

@property (nonatomic, strong) UIImage* avatar;
@property (nonatomic, strong) NSArray* emails;
@property (nonatomic, strong) NSString* fullname;
@property (nonatomic, weak) InfinitUser* infinit_user;
@property (nonatomic, strong) NSArray* phone_numbers;


- (id)initWithABRecord:(ABRecordRef)record;
- (id)initWithInfinitUser:(InfinitUser*)user;

- (void)addInfinitUser:(InfinitUser*)user;

@end
