//
//  InfinitSendContactsHeaderView.m
//  Infinit
//
//  Created by Christopher Crone on 12/01/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitSendContactsHeaderView.h"

#import "InfinitColor.h"

@implementation InfinitSendContactsHeaderView

- (void)awakeFromNib
{
  self.layer.borderColor = [InfinitColor colorWithGray:216].CGColor;
  self.layer.borderWidth = 1.0f;
}

@end
