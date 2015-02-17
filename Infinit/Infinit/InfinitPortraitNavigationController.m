//
//  InfinitPortraitNavigationController.m
//  Infinit
//
//  Created by Christopher Crone on 27/01/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitPortraitNavigationController.h"

@interface InfinitPortraitNavigationController ()

@end

@implementation InfinitPortraitNavigationController

#pragma mark - Rotation

- (BOOL)shouldAutorotate
{
  return NO;
}

- (NSUInteger)supportedInterfaceOrientations
{
  return UIInterfaceOrientationMaskPortrait;
}

@end
