//
//  InfinitWelcomeCodeViewController.h
//  Infinit
//
//  Created by Christopher Crone on 23/04/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol InfinitWelcomeCodeProtocol;

@interface InfinitWelcomeCodeViewController : UIViewController

@property (nonatomic, weak) id <InfinitWelcomeCodeProtocol> delegate;

@end

@protocol InfinitWelcomeCodeProtocol <NSObject>

- (void)welcomeCode:(InfinitWelcomeCodeViewController*)sender
       doneWithCode:(NSString*)code;

@end
