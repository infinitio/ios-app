//
//  InfinitWelcomeOnboardingNavigationController.m
//  Infinit
//
//  Created by Christopher Crone on 04/02/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitWelcomeOnboardingNavigationController.h"

@interface InfinitWelcomeOnboardingNavigationController ()

@end

@implementation InfinitWelcomeOnboardingNavigationController

- (void)onboardingDone
{
  [self.delegate welcomeOnboardingDone];
}

@end
