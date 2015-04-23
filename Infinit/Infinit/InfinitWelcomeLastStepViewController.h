//
//  InfinitWelcomeLastStepViewController.h
//  Infinit
//
//  Created by Christopher Crone on 23/04/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <Gap/InfinitStateResult.h>

@protocol InfinitWelcomeLastStepProtocol;

typedef void(^InfinitWelcomeLastStepBlock)(InfinitStateResult* result);

@interface InfinitWelcomeLastStepViewController : UIViewController

@property (nonatomic, weak) id<InfinitWelcomeLastStepProtocol> delegate;

@end

@protocol InfinitWelcomeLastStepProtocol <NSObject>

- (void)welcomeLastStepBack:(InfinitWelcomeLastStepViewController*)sender;
- (void)welcomeLastStepRegister:(InfinitWelcomeLastStepViewController*)sender
                           name:(NSString*)name
                       password:(NSString*)password
                completionBlock:(InfinitWelcomeLastStepBlock)completion_block;
- (void)welcomeLastStepFacebookConnect:(InfinitWelcomeLastStepViewController*)sender
                       completionBlock:(InfinitWelcomeLastStepBlock)completion_block;
- (void)welcomeLastStepDone:(InfinitWelcomeLastStepViewController*)sender;

- (NSString*)welcomeLastStep:(InfinitWelcomeLastStepViewController*)sender
             errorFromStatus:(gap_Status)status;

@end
