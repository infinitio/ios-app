//
//  InfinitSendTableHeader.m
//  Infinit
//
//  Created by Christopher Crone on 16/01/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitSendTableHeader.h"

#import "InfinitColor.h"

@implementation InfinitSendTableHeader

- (void)awakeFromNib
{
  self.layer.borderColor = [InfinitColor colorWithGray:216].CGColor;
  self.layer.borderWidth = 1.0f;
}

@end
