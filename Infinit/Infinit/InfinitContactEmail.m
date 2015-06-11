//
//  InfinitContactEmail.m
//  Infinit
//
//  Created by Christopher Crone on 02/06/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitContactEmail.h"

@implementation InfinitContactEmail

#pragma mark - Init

- (instancetype)initWithEmail:(NSString*)email_
{
  NSString* email = [InfinitContactEmail trimEmail:email_];
  if (self = [super initWithAvatar:nil firstName:email fullname:email])
  {
    _email = email;
  }
  return self;
}

+ (instancetype)contactWithEmail:(NSString*)email
{
  return [[self alloc] initWithEmail:email];
}

#pragma mark - NSObject

- (instancetype)copyWithZone:(NSZone*)zone
{
  InfinitContactEmail* res = [[[self class] allocWithZone:zone] init];
  res->_email = [self.email copy];
  return res;
}

- (NSString*)description
{
  return [NSString stringWithFormat:@"<%@> email: %@", self.fullname, self.email];
}

- (BOOL)isEqual:(id)object
{
  if (![object isKindOfClass:self.class])
    return NO;
  InfinitContactEmail* other = (InfinitContactEmail*)object;
  if ([self.email isEqualToString:other.email])
    return YES;
  return NO;
}

#pragma mark - Helpers

+ (NSString*)trimEmail:(NSString*)string
{
  return [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]].lowercaseString;
}

@end
