//
//  InfinitDevicePasswordManager.h
//  Infinit
//
//  Created by Christopher Crone on 08/09/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface InfinitDevicePasswordManager : NSObject

+ (void)checkForExistingDeviceIdForAccount:(NSString*)identifier;

+ (void)ensureDeviceIdStoredForAccount:(NSString*)identifier;

+ (NSString*)deviceIdForAccount:(NSString*)identifier;

+ (NSString*)passwordForAccount:(NSString*)identifier;

+ (void)storeDeviceIdWithPassword:(NSString*)password
                    forIdentifier:(NSString*)identifier;

@end
