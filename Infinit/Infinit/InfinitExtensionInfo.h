//
//  InfinitExtensionInfo.h
//  Infinit
//
//  Created by Christopher Crone on 09/04/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "InfinitConstants.h"

/// Ping/pong notifications.
#define INFINIT_PING_NOTIFICATION @"INFINIT_PING_NOTIFICATION"
#define INFINIT_PONG_NOTIFICATION @"INFINIT_PONG_NOTIFICATION"

/// Extension notifications.
#define INFINIT_EXTENSION_FILES_NOTIFICATION @"INFINIT_EXTENSION_FILES_NOTIFICATION"

@interface InfinitExtensionInfo : NSObject

+ (instancetype)sharedInstance;

- (NSString*)files_path;
- (NSString*)internal_files_path;

@end
