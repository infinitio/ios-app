//
//  InfinitWelcomeEmailViewController.h
//  Infinit
//
//  Created by Christopher Crone on 23/04/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "InfinitWelcomeAbstractViewController.h"

@protocol InfinitWelcomeEmailProtocol;

typedef void(^InfinitWelcomeEmailBlock)();

@interface InfinitWelcomeEmailViewController : InfinitWelcomeAbstractViewController

@property (nonatomic, weak) id<InfinitWelcomeEmailProtocol> delegate;
@property (nonatomic, readwrite) NSString* email;

- (void)gotEmailAccountType;

@end

@protocol InfinitWelcomeEmailProtocol <NSObject>

- (void)welcomeEmailBack:(InfinitWelcomeEmailViewController*)sender;
- (void)welcomeEmailNext:(InfinitWelcomeEmailViewController*)sender
               withEmail:(NSString*)email
         completionBlock:(InfinitWelcomeEmailBlock)completion_block;
- (void)welcomeEmailFacebook:(InfinitWelcomeEmailViewController*)sender;

@end
