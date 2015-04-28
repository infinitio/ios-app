//
//  InfinitWelcomeOnboardingNavigationController.m
//  Infinit
//
//  Created by Christopher Crone on 28/04/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitWelcomeOnboardingNavigationController.h"

@interface InfinitWelcomeOnboardingNavigationController ()

@end

@implementation InfinitWelcomeOnboardingNavigationController

- (void)viewDidLoad
{
  [super viewDidLoad];
}

#pragma mark - Rotation

- (BOOL)shouldAutorotate
{
  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
    return NO;
  return [super shouldAutorotate];
}

- (NSUInteger)supportedInterfaceOrientations
{
  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
    return UIInterfaceOrientationMaskPortrait;
  return [super supportedInterfaceOrientations];
}

@end
