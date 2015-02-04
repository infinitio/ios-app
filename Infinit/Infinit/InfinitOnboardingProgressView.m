//
//  InfinitOnboardingProgressView.m
//  Infinit
//
//  Created by Christopher Crone on 04/02/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitOnboardingProgressView.h"

#import "InfinitColor.h"

@interface InfinitOnboardingProgressView ()

@property (nonatomic, weak) IBOutlet UIView* dot_1;
@property (nonatomic, weak) IBOutlet UIView* dot_2;
@property (nonatomic, weak) IBOutlet UIView* dot_3;

@property (nonatomic, weak) NSArray* dots;

@end

@implementation InfinitOnboardingProgressView

- (void)awakeFromNib
{
  self.dot_1.layer.cornerRadius = self.dot_1.bounds.size.height / 2.0f;
  self.dot_2.layer.cornerRadius = self.dot_2.bounds.size.height / 2.0f;
  self.dot_3.layer.cornerRadius = self.dot_3.bounds.size.height / 2.0f;
}

@end
