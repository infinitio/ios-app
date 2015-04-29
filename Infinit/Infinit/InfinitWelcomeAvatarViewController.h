//
//  InfinitWelcomeAvatarViewController.h
//  Infinit
//
//  Created by Christopher Crone on 28/04/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "InfinitWelcomeAbstractViewController.h"

@protocol InfinitWelcomeAvatarProtocol;

@interface InfinitWelcomeAvatarViewController : InfinitWelcomeAbstractViewController

@property (nonatomic, weak) id<InfinitWelcomeAvatarProtocol> delegate;

@end

@protocol InfinitWelcomeAvatarProtocol <NSObject>

- (void)welcomeAvatarDone:(InfinitWelcomeAvatarViewController*)sender
               withAvatar:(UIImage*)avatar;

@end
