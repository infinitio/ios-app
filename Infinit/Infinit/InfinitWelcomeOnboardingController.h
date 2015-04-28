//
//  InfinitWelcomeOnboardingController.h
//  Infinit
//
//  Created by Christopher Crone on 04/02/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol InfinitWelcomeOnboardingProtocol;

@interface InfinitWelcomeOnboardingController : UIViewController

@property (nonatomic, weak) id<InfinitWelcomeOnboardingProtocol> delegate;

@end

@protocol InfinitWelcomeOnboardingProtocol <UINavigationControllerDelegate>

- (void)welcomeOnboardingDone;

@end
