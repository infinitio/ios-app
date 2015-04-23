//
//  InfinitWelcomeEmailViewController.h
//  Infinit
//
//  Created by Christopher Crone on 23/04/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol InfinitWelcomeEmailProtocol;

@interface InfinitWelcomeEmailViewController : UIViewController

@property (nonatomic, weak) id<InfinitWelcomeEmailProtocol> delegate;

@end

@protocol InfinitWelcomeEmailProtocol <NSObject>

- (void)welcomeEmailBack:(InfinitWelcomeEmailViewController*)sender;
- (void)welcomeEmailNext:(InfinitWelcomeEmailViewController*)sender
               withEmail:(NSString*)email;
- (void)welcomeEmailFacebook:(InfinitWelcomeEmailViewController*)sender;

@end
