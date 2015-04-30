//
//  InfinitCodeManager.m
//  Infinit
//
//  Created by Christopher Crone on 29/04/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitCodeManager.h"

#import "InfinitConstants.h"
#import "InfinitMetricsManager.h"

#import <Gap/InfinitStateManager.h>

#undef check
#import <elle/log.hh>

ELLE_LOG_COMPONENT("iOS.CodeManager");

@interface InfinitCodeManager ()

@property (atomic, readonly) BOOL valid;

@end

static InfinitCodeManager* _instance = nil;
static dispatch_once_t _instance_token = 0;

@implementation InfinitCodeManager

@synthesize code = _code;

#pragma mark - Init

- (instancetype)init
{
  NSCAssert(_instance == nil, @"Use sharedInstance.");
  if (self = [super init])
  {}
  return self;
}

+ (instancetype)sharedInstance
{
  dispatch_once(&_instance_token, ^
  {
    _instance = [[InfinitCodeManager alloc] init];
  });
  return _instance;
}

#pragma mark - General

- (NSString*)code
{
  if (self.valid)
    return _code;
  return nil;
}

- (void)setCode:(NSString*)code
{
  if (code == nil)
    return;
  __weak InfinitCodeManager* weak_self = self;
  [[InfinitStateManager sharedInstance] ghostCodeExists:code
                                        completionBlock:^(InfinitStateResult* result,
                                                          NSString* code,
                                                          BOOL valid)
  {
    InfinitCodeManager* strong_self = weak_self;
    strong_self->_valid = valid;
    if (valid)
    {
      strong_self->_code = code;
      [InfinitMetricsManager sendMetric:InfinitUIEventGotLinkCode method:InfinitUIMethodValid];
      ELLE_LOG("%s: got valid code: %s", strong_self.description.UTF8String, code.UTF8String);
    }
    else
    {
      [InfinitMetricsManager sendMetric:InfinitUIEventGotLinkCode method:InfinitUIMethodInvalid];
      ELLE_LOG("%s: got invalid code: %s", strong_self.description.UTF8String, code.UTF8String);
    }
  }];
}

- (BOOL)has_code
{
  return self.code.length;
}

- (void)codeConsumed
{
  _code = nil;
  _valid = NO;
}

- (BOOL)getCodeFromURL:(NSURL*)url
{
  if (![url.scheme isEqualToString:kInfinitURLScheme])
    return NO;
  NSString* resource_specifier = [url.resourceSpecifier substringFromIndex:2];
  NSArray* components = [resource_specifier componentsSeparatedByString:@"/"];
  if ([components[0] isEqual:@"invitation"])
  {
    NSString* possible_code = nil;
    if ([components[1] rangeOfString:@"?"].location != NSNotFound)
    {
      possible_code = [components[1] componentsSeparatedByString:@"?"][0];
    }
    else
    {
      possible_code = components[1];
    }
    self.code = possible_code;
  }
  return NO;
}

@end
