//
//  InfinitLinkTransactionCell.m
//  Infinit
//
//  Created by Christopher Crone on 13/11/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import "InfinitLinkTransactionCell.h"

@implementation InfinitLinkTransactionCell

- (void)setupCellWithTransaction:(InfinitLinkTransaction*)transaction
{
//  self.click_count.text = [NSString stringWithFormat:@"%@", transaction.click_count];
  self.link.text = transaction.link;
  self.name.text = transaction.name;
}

@end
