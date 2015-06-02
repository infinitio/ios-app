//
//  InfinitContactEmail.h
//  Infinit
//
//  Created by Christopher Crone on 02/06/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitContact.h"

@interface InfinitContactEmail : InfinitContact

@property (nonatomic, readonly) NSString* email;

+ (instancetype)contactWithEmail:(NSString*)email;

@end
