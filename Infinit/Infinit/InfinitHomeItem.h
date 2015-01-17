//
//  InfinitHomeItem.h
//  Infinit
//
//  Created by Christopher Crone on 17/01/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Gap/InfinitTransaction.h>

@interface InfinitHomeItem : NSObject

@property (nonatomic, readonly) InfinitTransaction* transaction;

- (id)initWithTransaction:(InfinitTransaction*)transaction;

@end
