//
//  InfinitContactUser.h
//  Infinit
//
//  Created by Christopher Crone on 02/06/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitContact.h"

#import <Gap/InfinitDevice.h>
#import <Gap/InfinitUser.h>

@interface InfinitContactUser : InfinitContact

@property (nonatomic, strong) InfinitDevice* device;
@property (nonatomic, readonly) NSString* device_name;
@property (nonatomic, weak) InfinitUser* infinit_user;

+ (instancetype)contactWithInfinitUser:(InfinitUser*)user;
+ (instancetype)contactWithInfinitUser:(InfinitUser*)user
                             andDevice:(InfinitDevice*)device;

- (void)updateAvatar;

@end
