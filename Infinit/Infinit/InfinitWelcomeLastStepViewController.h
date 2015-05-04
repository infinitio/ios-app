//
//  InfinitWelcomeLastStepViewController.h
//  Infinit
//
//  Created by Christopher Crone on 23/04/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "InfinitWelcomeAbstractViewController.h"

@protocol InfinitWelcomeLastStepProtocol;

@interface InfinitWelcomeLastStepViewController : InfinitWelcomeAbstractViewController

@property (nonatomic, weak) id<InfinitWelcomeLastStepProtocol> delegate;

@property (nonatomic, readwrite) NSString* name;

@end

@protocol InfinitWelcomeLastStepProtocol <InfinitWelcomeAbstractProtocol>

- (void)welcomeLastStepBack:(InfinitWelcomeLastStepViewController*)sender;
- (void)welcomeLastStepRegister:(InfinitWelcomeLastStepViewController*)sender
                           name:(NSString*)name
                       password:(NSString*)password
                completionBlock:(InfinitWelcomeResultBlock)completion_block;
- (void)welcomeLastStepFacebookConnect:(InfinitWelcomeLastStepViewController*)sender;
- (void)welcomeLastStepDone:(InfinitWelcomeLastStepViewController*)sender;

@end
