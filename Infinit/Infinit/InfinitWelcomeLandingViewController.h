//
//  InfinitWelcomeLandingViewController.h
//  Infinit
//
//  Created by Christopher Crone on 23/04/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol InfinitWelcomeLandingProtocol;

@interface InfinitWelcomeLandingViewController : UIViewController

@property (nonatomic, weak) id<InfinitWelcomeLandingProtocol> delegate;

@end

@protocol InfinitWelcomeLandingProtocol <NSObject>

- (void)welcomeLandingHaveAccount:(InfinitWelcomeLandingViewController*)sender;
- (void)welcomeLandingNoAccount:(InfinitWelcomeLandingViewController*)sender;

@end
