//
//  InfinitDevicePasswordManager.m
//  Infinit
//
//  Created by Christopher Crone on 08/09/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitDevicePasswordManager.h"

#import "InfinitApplicationSettings.h"

#import <Gap/InfinitDirectoryManager.h>
#import <Gap/InfinitKeychain.h>
#import <Gap/InfinitStateManager.h>

#define kInfinitUUIDLength 36

@implementation InfinitDevicePasswordManager

+ (void)checkForExistingDeviceIdForAccount:(NSString*)identifier
{
  NSString* combined = [[InfinitKeychain sharedInstance] passwordForAccount:identifier];
  NSString* device_id = [self uuidStringFromString:combined];
  if (!combined.length || !device_id.length || [[self diskDeviceId] isEqualToString:device_id])
    return;
  [[InfinitStateManager sharedInstance] changeDeviceId:device_id];
}

+ (void)ensureDeviceIdStoredForAccount:(NSString*)identifier
{
  if ([InfinitApplicationSettings sharedInstance].stored_device_id)
    return;
  NSString* combined = [[InfinitKeychain sharedInstance] passwordForAccount:identifier];
  NSString* device_id = [self uuidStringFromString:combined];
  if (!combined.length || device_id.length)
    return;
  NSString* password = combined;
  device_id = [self diskDeviceId];
  if (!device_id.length)
    return;
  [[InfinitKeychain sharedInstance] updatePassword:[device_id stringByAppendingString:password]
                                        forAccount:identifier];
  [InfinitApplicationSettings sharedInstance].stored_device_id = YES;
}

+ (NSString*)deviceIdForAccount:(NSString*)identifier
{
  NSString* combined = [[InfinitKeychain sharedInstance] passwordForAccount:identifier];
  return [self uuidStringFromString:combined];
}

+ (NSString*)passwordForAccount:(NSString*)identifier
{
  NSString* combined = [[InfinitKeychain sharedInstance] passwordForAccount:identifier];
  NSString* device_id = [self uuidStringFromString:combined];
  if (!device_id.length)
  {
    if (combined.length)
      return combined;
    else
      return nil;
  }
  return [combined substringFromIndex:kInfinitUUIDLength];
}

+ (void)storeDeviceIdWithPassword:(NSString*)password
                    forIdentifier:(NSString*)identifier
{
  NSString* to_store = [self diskDeviceId];
  if (password.length)
    to_store = [to_store stringByAppendingString:password];
  if (!to_store.length)
    return;
  if ([[InfinitKeychain sharedInstance] passwordForAccount:identifier].length)
    [[InfinitKeychain sharedInstance] updatePassword:to_store forAccount:identifier];
  else
    [[InfinitKeychain sharedInstance] addPassword:to_store forAccount:identifier];
  [InfinitApplicationSettings sharedInstance].stored_device_id = YES;
}

#pragma mark - Helpers

+ (NSString*)diskDeviceId
{
  NSError* error = nil;
  InfinitDirectoryManager* manager = [InfinitDirectoryManager sharedInstance];
  NSString* res = [NSString stringWithContentsOfFile:manager.device_id_file
                                            encoding:NSUTF8StringEncoding
                                               error:&error];
  NSCharacterSet* white_space = [NSCharacterSet whitespaceAndNewlineCharacterSet];
  return [res stringByTrimmingCharactersInSet:white_space];
}

+ (NSString*)uuidStringFromString:(NSString*)string
{
  if (string.length >= kInfinitUUIDLength)
  {
    NSString* possible_uuid = [string substringToIndex:kInfinitUUIDLength];
    NSUUID* uuid = [[NSUUID alloc] initWithUUIDString:possible_uuid];
    if (uuid == nil)
      return nil;
    return uuid.UUIDString.lowercaseString;
  }
  return nil;
}

@end
