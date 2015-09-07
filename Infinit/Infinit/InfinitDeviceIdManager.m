//
//  InfinitDeviceIdManager.m
//  Infinit
//
//  Created by Christopher Crone on 07/09/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitDeviceIdManager.h"

#import <Gap/InfinitDirectoryManager.h>
#import <Gap/InfinitKeychain.h>

static InfinitDeviceIdManager* _instance = nil;
static dispatch_once_t _instance_token = 0;

static NSString* kInfinitKeychainDeviceIdKey = @"io.Infinit.Keychain.DeviceId";

@implementation InfinitDeviceIdManager

#pragma mark - Init

- (instancetype)init
{
  NSAssert(_instance == nil, @"Use sharedInstance.");
  if (self = [super init])
  {}
  return self;
}

+ (instancetype)sharedInstance
{
  dispatch_once(&_instance_token, ^
  {
    _instance = [[self alloc] init];
  });
  return _instance;
}

#pragma mark - External

- (void)_checkExistingOrStoreCurrentDeviceId
{
  NSString* keychain_device_id =
    [[InfinitKeychain sharedInstance] passwordForAccount:kInfinitKeychainDeviceIdKey];
  InfinitDirectoryManager* dir_manager = [InfinitDirectoryManager sharedInstance];
  NSError* error = nil;
  NSString* disk_device_id = [NSString stringWithContentsOfFile:dir_manager.device_id_file
                                                       encoding:NSUTF8StringEncoding
                                                          error:&error];
  if (keychain_device_id.length && !disk_device_id.length)
  {
    [keychain_device_id writeToFile:dir_manager.device_id_file
                         atomically:NO 
                           encoding:NSUTF8StringEncoding 
                              error:nil];
  }
  else if (disk_device_id.length && !keychain_device_id.length)
  {
    [[InfinitKeychain sharedInstance] storePersistentData:disk_device_id
                                                   forKey:kInfinitKeychainDeviceIdKey];
  }
}

+ (void)checkExistingOrStoreCurrentDeviceId
{
  [[self sharedInstance] _checkExistingOrStoreCurrentDeviceId];
}

@end
