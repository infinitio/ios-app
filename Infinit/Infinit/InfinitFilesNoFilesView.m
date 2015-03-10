//
//  InfinitFilesNoFilesView.m
//  Infinit
//
//  Created by Christopher Crone on 10/03/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitFilesNoFilesView.h"

#import "InfinitHostDevice.h"

@interface InfinitFilesNoFilesView ()

@property (nonatomic, weak) IBOutlet NSLayoutConstraint* top_constraint;

@end

@implementation InfinitFilesNoFilesView

- (void)awakeFromNib
{
  [super awakeFromNib];
  if ([InfinitHostDevice smallScreen])
    self.top_constraint.constant -= 40.0f;
}

@end
