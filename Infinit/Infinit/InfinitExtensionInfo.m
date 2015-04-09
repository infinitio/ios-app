//
//  InfinitExtensionInfo.m
//  Infinit
//
//  Created by Christopher Crone on 09/04/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitExtensionInfo.h"

static dispatch_once_t _instance_token = 0;
static InfinitExtensionInfo* _instance = nil;

@implementation InfinitExtensionInfo

+ (instancetype)sharedInstance
{
  dispatch_once(&_instance_token, ^
  {
    _instance = [[InfinitExtensionInfo alloc] init];
  });
  return _instance;
}

- (NSString*)files_path
{
  @synchronized(self)
  {
    NSString* res = [self.root_path stringByAppendingPathComponent:@"external_files"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:res])
    {
      [[NSFileManager defaultManager] createDirectoryAtPath:res
                                withIntermediateDirectories:YES
                                                 attributes:@{NSURLIsExcludedFromBackupKey: @YES}
                                                      error:nil];
    }
    return res;
  }
}

- (NSString*)internal_files_path
{
  @synchronized(self)
  {
    NSString* res = [self.root_path stringByAppendingPathComponent:@"internal_files"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:res])
    {
      [[NSFileManager defaultManager] createDirectoryAtPath:res
                                withIntermediateDirectories:YES
                                                 attributes:@{NSURLIsExcludedFromBackupKey: @YES}
                                                      error:nil];
    }
    return res;
  }
}

- (NSString*)root_path
{
  NSFileManager* manager = [NSFileManager defaultManager];
  NSURL* shared_url =
  [manager containerURLForSecurityApplicationGroupIdentifier:kInfinitAppGroupName];
  NSString* res = [shared_url.path stringByAppendingPathComponent:@"extension"];
  if (![manager fileExistsAtPath:res])
  {
    [manager createDirectoryAtPath:res
       withIntermediateDirectories:YES
                        attributes:@{NSURLIsExcludedFromBackupKey: @YES}
                             error:nil];
  }
  return res;
}

@end
