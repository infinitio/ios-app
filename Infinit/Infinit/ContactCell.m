//
//  ContactCell.m
//  Infinit
//
//  Created by Michael Dee on 12/21/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import "ContactCell.h"

@implementation ContactCell


- (void)prepareForReuse
{
  self.nameLabel.text = nil;
}

@end
