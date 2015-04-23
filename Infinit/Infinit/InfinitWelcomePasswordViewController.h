//
//  InfinitWelcomePasswordViewController.h
//  Infinit
//
//  Created by Christopher Crone on 23/04/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <Gap/InfinitStateResult.h>

@protocol InfinitWelcomePasswordProtocol;

typedef void(^InfinitWelcomePasswordBlock)(InfinitStateResult* result);

@interface InfinitWelcomePasswordViewController : UIViewController

@property (nonatomic, weak) id<InfinitWelcomePasswordProtocol> delegate;

@end

@protocol InfinitWelcomePasswordProtocol <NSObject>

- (void)welcomePasswordBack:(InfinitWelcomePasswordViewController*)sender;
- (void)welcomePasswordDone:(InfinitWelcomePasswordViewController*)sender;
- (void)welcomePasswordLogin:(InfinitWelcomePasswordViewController*)sender
                    password:(NSString*)password
             completionBlock:(InfinitWelcomePasswordBlock)completion_block;

- (NSString*)welcomePassword:(InfinitWelcomePasswordViewController*)sender
             errorFromStatus:(gap_Status)status;

@end
