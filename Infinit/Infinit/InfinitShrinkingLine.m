//
//  InfinitShrinkingLine.m
//  Infinit
//
//  Created by Christopher Crone on 20/02/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitShrinkingLine.h"

@interface InfinitShrinkingLine ()

@property (nonatomic, weak) IBOutlet NSLayoutConstraint* h_constraint;

@end

@implementation InfinitShrinkingLine

- (void)setHidden:(BOOL)hidden
{
  self.h_constraint.constant = hidden ? 0.0f : 1.0f;
  [super setHidden:hidden];
}

@end
