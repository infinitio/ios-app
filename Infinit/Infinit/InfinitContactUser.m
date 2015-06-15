//
//  InfinitContactUser.m
//  Infinit
//
//  Created by Christopher Crone on 02/06/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitContactUser.h"

@implementation InfinitContactUser

#pragma mark - Init

+ (instancetype)contactWithInfinitUser:(InfinitUser*)user
{
  return [[self alloc] initWithInfinitUser:user andDevice:nil];
}

- (instancetype)initWithInfinitUser:(InfinitUser*)user
                          andDevice:(InfinitDevice*)device
{
  NSString* fullname = nil;
  if (user.is_self)
    fullname = NSLocalizedString(@"Me", nil);
  else
    fullname = user.fullname;
  NSString* first_name = nil;
  NSArray* temp = [user.fullname componentsSeparatedByString:@" "];
  if (temp.count > 0 && [temp[0] length] > 0)
    first_name = temp[0];
  else
    first_name = user.fullname;
  if (self = [super initWithAvatar:user.avatar firstName:first_name fullname:fullname])
  {
    _infinit_user = user;
    _device = device;
  }
  return self;
}

+ (instancetype)contactWithInfinitUser:(InfinitUser*)user
                             andDevice:(InfinitDevice*)device
{
  return [[self alloc] initWithInfinitUser:user andDevice:device];
}

#pragma mark - InfinitContact

- (BOOL)containsSearchString:(NSString*)search_string
{
  NSUInteger score = 0;
  NSString* trimmed_string = search_string;
  [search_string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
  NSArray* components = [trimmed_string componentsSeparatedByString:@" "];
  for (NSString* component in components)
  {
    if ([super containsSearchString:search_string] ||
        (self.infinit_user != nil &&
         [self source:self.infinit_user.handle containsString:component]) ||
        (self.device != nil && [self source:self.device_name containsString:component]))
    {
      score++;
    }
  }
  if (score == components.count)
    return YES;
  return NO;
}

#pragma mark - General

- (void)updateAvatar
{
  self.avatar = self.infinit_user.avatar;
}

- (NSString*)device_name
{
  if (self.device == nil)
    return nil;
  return self.device.name;
}

#pragma mark - NSObject

- (instancetype)copyWithZone:(NSZone*)zone
{
  InfinitContactUser* res = [super copyWithZone:zone];
  res->_infinit_user = self.infinit_user;
  res->_device = self.device;
  return res;
}

- (NSString*)description
{
  return [NSString stringWithFormat:@"<%@> infinit:%@\rdevice: %@",
          self.fullname, self.infinit_user, self.device];
}

- (BOOL)isEqual:(id)object
{
  if (![object isKindOfClass:self.class])
    return NO;
  InfinitContactUser* other = (InfinitContactUser*)object;
  if (self.infinit_user && other.infinit_user && [self.infinit_user isEqual:other.infinit_user])
  {
    if (self.infinit_user.is_self)
    {
      if ([self.device isEqual:other.device])
        return YES;
    }
    else
    {
      return YES;
    }
  }
  return NO;
}

@end
