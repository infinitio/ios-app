//
//  InfinitWelcomeNavigationController.m
//  Infinit
//
//  Created by Christopher Crone on 30/04/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitWelcomeNavigationController.h"

@interface InfinitWelcomeNavigationController ()

@end

@implementation InfinitWelcomeNavigationController

- (BOOL)shouldAutorotate
{
  return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
  return UIInterfaceOrientationMaskPortrait;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
  return UIInterfaceOrientationPortrait;
}

@end
