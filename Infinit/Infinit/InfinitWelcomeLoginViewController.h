//
//  InfinitWelcomeLoginViewController.h
//  Infinit
//
//  Created by Christopher Crone on 24/04/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "InfinitWelcomeAbstractViewController.h"

@protocol InfinitWelcomeLoginProtocol;

@interface InfinitWelcomeLoginViewController : InfinitWelcomeAbstractViewController

@property (nonatomic, weak) id<InfinitWelcomeLoginProtocol> delegate;

@end

@protocol InfinitWelcomeLoginProtocol <InfinitWelcomeAbstractProtocol>

- (void)welcomeLoginBack:(InfinitWelcomeLoginViewController*)sender;
- (void)welcomeLoginDone:(InfinitWelcomeLoginViewController*)sender;
- (void)welcomeLogin:(InfinitWelcomeLoginViewController*)sender
               email:(NSString*)email
            password:(NSString*)password
     completionBlock:(InfinitWelcomeResultBlock)completion_block;
- (void)welcomeLoginFacebook:(InfinitWelcomeLoginViewController*)sender;

@end
