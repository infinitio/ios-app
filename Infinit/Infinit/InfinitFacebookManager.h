//
//  InfinitFacebookManager.h
//  Infinit
//
//  Created by Christopher Crone on 29/05/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FBSDKLoginManager;

@interface InfinitFacebookManager : NSObject

@property (nonatomic, readonly) FBSDKLoginManager* login_manager;

+ (instancetype)sharedInstance;

- (void)logout;

@end
