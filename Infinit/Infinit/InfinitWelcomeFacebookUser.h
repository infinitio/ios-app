//
//  InfinitWelcomeFacebookUser.h
//  Infinit
//
//  Created by Christopher Crone on 26/04/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <UIKit/UIKit.h>
#import <surface/gap/enums.hh>

@interface InfinitWelcomeFacebookUser : NSObject

@property (nonatomic, readwrite) AccountStatus account_status;
@property (nonatomic, readonly) UIImage* avatar;
@property (nonatomic, readwrite) NSString* email;
@property (nonatomic, readonly) NSString* id_;
@property (nonatomic, readonly) NSString* name;

+ (instancetype)facebookUser:(NSString*)facebook_id
                       email:(NSString*)email
                        name:(NSString*)name
                      avatar:(UIImage*)avatar;

@end
