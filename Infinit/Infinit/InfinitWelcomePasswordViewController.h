//
//  InfinitWelcomePasswordViewController.h
//  Infinit
//
//  Created by Christopher Crone on 23/04/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "InfinitWelcomeAbstractViewController.h"

#import <Gap/InfinitStateResult.h>

@protocol InfinitWelcomePasswordProtocol;

@interface InfinitWelcomePasswordViewController : InfinitWelcomeAbstractViewController

@property (nonatomic, weak) id<InfinitWelcomePasswordProtocol> delegate;
@property (nonatomic, readwrite) BOOL hide_facebook_button;

@end

@protocol InfinitWelcomePasswordProtocol <InfinitWelcomeAbstractProtocol>

- (void)welcomePasswordBack:(InfinitWelcomePasswordViewController*)sender;
- (void)welcomePasswordDone:(InfinitWelcomePasswordViewController*)sender;
- (void)welcomePasswordLogin:(InfinitWelcomePasswordViewController*)sender
                    password:(NSString*)password
             completionBlock:(InfinitWelcomeResultBlock)completion_block;
- (void)welcomePasswordFacebook:(InfinitWelcomePasswordViewController*)sender;

@end
