//
//  InfinitKeychain.m
//  Infinit
//
//  Created by Christopher Crone on 14/01/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitKeychain.h"

#import <Security/Security.h>

static InfinitKeychain* _instance = nil;

@implementation InfinitKeychain
{
@private
  NSString* _service_name;
}

#pragma mark Init

- (id)init
{
  NSCAssert(_instance == nil, @"Use the sharedInstance");
  if (self = [super init])
  {
    _service_name = @"Infinit";
  }
  return self;
}

+ (instancetype)sharedInstance
{
  if (_instance == nil)
    _instance = [[InfinitKeychain alloc] init];
  return _instance;
}

#pragma mark Keychain Operations

- (BOOL)addPassword:(NSString*)password
         forAccount:(NSString*)account
{
  NSMutableDictionary* dict = [self keychainDictionaryForAccount:account];
  dict[(__bridge id)kSecValueData] = [self encodeString:password];
  OSStatus status = SecItemAdd((__bridge CFDictionaryRef)dict, NULL);
  if (status != errSecSuccess)
  {
    NSLog(@"Unable to add item: %d", (int)status);
    return NO;
  }
  return YES;
}

- (BOOL)credentialsForAccountInKeychain:(NSString*)account
{
  if ([self passwordForAccount:account] == nil)
    return NO;
  return YES;
}

- (NSString*)passwordForAccount:(NSString*)account
{
  NSMutableDictionary* dict = [self keychainDictionaryForAccount:account];
  dict[(__bridge id)kSecMatchLimit] = (__bridge id)kSecMatchLimitOne;
  dict[(__bridge id)kSecReturnData] = (id)kCFBooleanTrue;
  CFTypeRef result = NULL;
  OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)dict, &result);
  if (status != errSecSuccess)
  {
    NSLog(@"Unable to find password for account (%@): %d", account, (int)status);
    return nil;
  }
  return [self decodeString:result];
}

- (BOOL)removeAccount:(NSString*)account
{
  NSMutableDictionary* dict = [self keychainDictionaryForAccount:account];
  OSStatus status = SecItemDelete((__bridge CFDictionaryRef)dict);
  if (status != errSecSuccess)
  {
    NSLog(@"Unable to delete keychain entry for account (%@): %d", account, (int)status);
    return NO;
  }
  return YES;
}

- (BOOL)updatePassword:(NSString*)password
            forAccount:(NSString*)account
{
  NSMutableDictionary* dict = [self keychainDictionaryForAccount:account];
  NSDictionary* update_dict = @{(__bridge id)kSecValueData: [self encodeString:password]};
  OSStatus status = SecItemUpdate((__bridge CFDictionaryRef)dict,
                                  (__bridge CFDictionaryRef)update_dict);
  if (status != errSecSuccess)
  {
    NSLog(@"Unable to update password for account (%@): %d", account, (int)status);
    return NO;
  }
  return YES;
}

#pragma mark Helpers

- (NSString*)decodeString:(CFTypeRef)data
{
  return [[NSString alloc] initWithData:(__bridge NSData*)data encoding:NSUTF8StringEncoding];
}

- (NSData*)encodeString:(NSString*)string
{
  return [string dataUsingEncoding:NSUTF8StringEncoding];
}

- (NSMutableDictionary*)keychainDictionaryForAccount:(NSString*)account_
{
  NSString* account = account_.lowercaseString;
  NSDictionary* res = @{
    (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
    (__bridge id)kSecAttrGeneric: [self encodeString:account],
    (__bridge id)kSecAttrAccount: [self encodeString:account],
    (__bridge id)kSecAttrService: [self encodeString:_service_name],
    (__bridge id)kSecAttrAccessible: (__bridge id)kSecAttrAccessibleAlwaysThisDeviceOnly
  };
  return [res mutableCopy];
}

@end
