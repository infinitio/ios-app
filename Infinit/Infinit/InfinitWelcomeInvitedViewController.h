//
//  InfinitWelcomeInvitedViewController.h
//  Infinit
//
//  Created by Christopher Crone on 23/04/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol InfinitWelcomeInvitedProtocol;

@interface InfinitWelcomeInvitedViewController : UIViewController

@property (nonatomic, weak) id<InfinitWelcomeInvitedProtocol> delegate;

@end

@protocol InfinitWelcomeInvitedProtocol <NSObject>

- (void)welcomeInvited:(InfinitWelcomeInvitedViewController*)sender;
- (void)welcomeNotInvited:(InfinitWelcomeInvitedViewController*)sender;

@end
