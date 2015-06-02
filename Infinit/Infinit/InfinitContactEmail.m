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

- (BOOL)isEqual:(id)object
{
  if (![object isKindOfClass:self.class])
    return NO;
  InfinitContactEmail* other = (InfinitContactEmail*)object;
  if ([self.email isEqualToString:other.email])
    return YES;
  return NO;
}

- (NSString*)description
{
  return [NSString stringWithFormat:@"<%@> email: %@", self.fullname, self.email];
}

#pragma mark - Helpers

+ (NSString*)trimEmail:(NSString*)string
{
  return [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]].lowercaseString;
}

@end
