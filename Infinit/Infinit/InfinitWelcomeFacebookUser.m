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

+ (instancetype)facebookUserFromGraphDictionary:(NSDictionary*)user_dict
{
  NSString* user_id = user_dict[@"id"];
  NSString* email = user_dict[@"email"];
  NSString* name = user_dict[@"name"];
  NSData* avatar_data =
    [NSData dataWithContentsOfURL:[InfinitWelcomeFacebookUser avatarURLForUserWithId:user_id]];
  UIImage* avatar = [UIImage imageWithData:avatar_data];
  return [[InfinitWelcomeFacebookUser alloc] initWithFacebookUser:user_id
                                                            email:email 
                                                             name:name 
                                                           avatar:avatar];
}

#pragma mark - Helpers

+ (NSURL*)avatarURLForUserWithId:(NSString*)id_
{
  NSString* str =
    [NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=large", id_];
  return [NSURL URLWithString:str];
}

@end
