//
//  InfinitContact.m
//  Infinit
//
//  Created by Christopher Crone on 12/01/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitContact.h"

@implementation InfinitContact

#pragma mark - Init

- (instancetype)initWithAvatar:(UIImage*)avatar
                     firstName:(NSString*)first_name
                      fullname:(NSString*)fullname
{
  if (self = [super init])
  {
    _avatar = avatar;
    _first_name = first_name;
    _fullname = fullname;
  }
  return self;
}

#pragma mark - Search

- (BOOL)containsSearchString:(NSString*)search_string
{
  NSUInteger score = 0;
  NSString* trimmed_string = search_string;
    [search_string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
  NSArray* components = [trimmed_string componentsSeparatedByString:@" "];
  for (NSString* component in components)
  {
    if ([self source:self.fullname containsString:component])
      score++;
  }
  if (score == components.count)
    return YES;
  return NO;
}

- (BOOL)source:(NSString*)source
containsString:(NSString*)string
{
  if ([source rangeOfString:string options:NSCaseInsensitiveSearch].location == NSNotFound)
    return NO;
  return YES;
}

@end
