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

- (void)gotAddressBookAccess;

@end
