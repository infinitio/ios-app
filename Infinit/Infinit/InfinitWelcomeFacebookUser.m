//
//  InfinitWelcomeFacebookUser.m
//  Infinit
//
//  Created by Christopher Crone on 26/04/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitWelcomeFacebookUser.h"

@implementation InfinitWelcomeFacebookUser

- (instancetype)initWithFacebookUser:(NSString*)facebook_id
                               email:(NSString*)email
                                name:(NSString*)name
                              avatar:(UIImage*)avatar
{
  if (self  = [super init])
  {
    _id_ = facebook_id;
    _email = email;
    _name = name;
    _avatar = avatar;
  }
  return self;
}

+ (instancetype)facebookUser:(NSString*)facebook_id
                       email:(NSString*)email
                        name:(NSString*)name
                      avatar:(UIImage*)avatar
{
  return [[InfinitWelcomeFacebookUser alloc] initWithFacebookUser:facebook_id
                                                            email:email
                                                             name:name 
                                                           avatar:avatar];
}

@end
