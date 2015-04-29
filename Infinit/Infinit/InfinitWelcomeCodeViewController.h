//
//  InfinitWelcomeCodeViewController.h
//  Infinit
//
//  Created by Christopher Crone on 23/04/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "InfinitWelcomeAbstractViewController.h"

@protocol InfinitWelcomeCodeProtocol;

@interface InfinitWelcomeCodeViewController : InfinitWelcomeAbstractViewController

@property (nonatomic, weak) id <InfinitWelcomeCodeProtocol> delegate;

- (void)facebookRegister;

@end

@protocol InfinitWelcomeCodeProtocol <NSObject>

- (void)welcomeCode:(InfinitWelcomeCodeViewController*)sender
       doneWithCode:(NSString*)code;

@end
