//
//  InfinitWelcomeOnboardingNavigationController.h
//  Infinit
//
//  Created by Christopher Crone on 04/02/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitPortraitNavigationController.h"

@protocol InfinitWelcomeOnboardingProtocol;

@interface InfinitWelcomeOnboardingNavigationController : InfinitPortraitNavigationController

@property (nonatomic, readwrite) id<InfinitWelcomeOnboardingProtocol> delegate;

- (void)onboardingDone;

@end

@protocol InfinitWelcomeOnboardingProtocol <NSObject>

- (void)welcomeOnboardingDone;

@end
