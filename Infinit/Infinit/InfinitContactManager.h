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

/** Upload contacts to Meta.
 This will only take place if we have access to the address book and if it hasn't been done before.
 */
- (void)uploadContacts;

@end
