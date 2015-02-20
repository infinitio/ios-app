//
//  InfinitHomeItem.m
//  Infinit
//
//  Created by Christopher Crone on 17/01/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitHomeItem.h"

@implementation InfinitHomeItem

- (id)initWithTransaction:(InfinitTransaction*)transaction
{
  if (self = [super init])
  {
    _transaction = transaction;
    _expanded = NO;
  }
  return self;
}

- (NSString*)description
{
  return [NSString stringWithFormat:@"HomeItem: transaction (%@), %@",
          self.transaction.id_, self.expanded ? @"expanded" : @"collapsed"];
}

@end
