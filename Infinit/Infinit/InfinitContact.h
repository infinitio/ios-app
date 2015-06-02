//
//  InfinitContact.h
//  Infinit
//
//  Created by Christopher Crone on 12/01/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface InfinitContact : NSObject

@property (nonatomic, strong) UIImage* avatar;
@property (nonatomic, strong) NSString* first_name;
@property (nonatomic, strong) NSString* fullname;

- (BOOL)containsSearchString:(NSString*)search_string;

#pragma mark - subclass
- (instancetype)initWithAvatar:(UIImage*)avatar
                     firstName:(NSString*)first_name
                      fullname:(NSString*)fullname;

- (BOOL)source:(NSString*)source
containsString:(NSString*)string;

@end

#import "InfinitContactAddressBook.h"
#import "InfinitContactEmail.h"
#import "InfinitContactUser.h"
