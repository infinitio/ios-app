//
//  InfinitContact.h
//  Infinit
//
//  Created by Christopher Crone on 12/01/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AddressBook/AddressBook.h>

#import <Gap/InfinitDevice.h>
#import <Gap/InfinitUser.h>

@interface InfinitContact : NSObject

@property (nonatomic, strong) UIImage* avatar;
@property (nonatomic, strong) InfinitDevice* device;
@property (nonatomic, readonly) NSString* device_name;
@property (nonatomic, strong) NSArray* emails;
@property (nonatomic, strong) NSString* first_name;
@property (nonatomic, strong) NSString* fullname;
@property (nonatomic, weak) InfinitUser* infinit_user;
@property (nonatomic, strong) NSArray* phone_numbers;
@property (nonatomic, readwrite) NSInteger selected_email_index;
@property (nonatomic, readwrite) NSInteger selected_phone_index;


- (id)initWithABRecord:(ABRecordRef)record;
- (id)initWithEmail:(NSString*)email;
- (id)initWithInfinitUser:(InfinitUser*)user;
- (id)initWithInfinitUser:(InfinitUser*)user
                andDevice:(InfinitDevice*)device;

- (BOOL)containsSearchString:(NSString*)search_string;
- (void)updateAvatar;

@end
