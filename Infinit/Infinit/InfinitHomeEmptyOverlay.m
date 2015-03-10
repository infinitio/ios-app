//
//  InfinitHomeEmptyOverlay.m
//  Infinit
//
//  Created by Christopher Crone on 10/03/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitHomeEmptyOverlay.h"

#import "InfinitHostDevice.h"

@interface InfinitHomeEmptyOverlay ()

@property (nonatomic, weak) IBOutlet NSLayoutConstraint* top_constraint;

@end

@implementation InfinitHomeEmptyOverlay

- (void)awakeFromNib
{
  [super awakeFromNib];
  if ([InfinitHostDevice smallScreen])
    self.top_constraint.constant -= 40.0f;
}

@end
