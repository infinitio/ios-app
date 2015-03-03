//
//  InfinitFacebookManager.h
//  Infinit
//
//  Created by Christopher Crone on 02/03/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <FacebookSDK/FacebookSDK.h>

@protocol InfinitFacebookManagerProtocol;

@interface InfinitFacebookManager : NSObject

@property (nonatomic, readonly) NSArray* permission_list;

@property (nonatomic, readonly) UIImage* user_avatar;
@property (nonatomic, readonly) NSString* user_name;

+ (instancetype)sharedInstance;

- (void)sessionStateChanged:(FBSession*)session
                      state:(FBSessionState)state
                      error:(NSError*)error;

- (void)cleanSession;
- (void)closeSession;

@end

@protocol InfinitFacebookManagerProtocol <NSObject>

- (void)facebookUserAvatarUpdated:(UIImage*)avatar;

@end
