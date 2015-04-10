//
//  InfinitExtensionMoreCell.m
//  Infinit
//
//  Created by Christopher Crone on 10/04/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitExtensionMoreCell.h"

#import "InfinitColor.h"

@interface InfinitExtensionMoreCell ()

@property (nonatomic, weak) IBOutlet UILabel* files_label;

@end

@implementation InfinitExtensionMoreCell

static UIImage* _icon_image = nil;

- (void)setCount:(NSUInteger)count
{
  self.files_label.text = [NSString stringWithFormat:@"+%lu", (unsigned long)count];
}

@end
