//
//  InfinitCodeManager.h
//  Infinit
//
//  Created by Christopher Crone on 29/04/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface InfinitCodeManager : NSObject

@property (nonatomic, readwrite) NSString* code;
@property (nonatomic, readonly) BOOL has_code;

+ (instancetype)sharedInstance;

/** Call when code manager should no longer keep code.
 */
- (void)codeConsumed;

/** Check a URL for a code and store it if there is one.
 @param url
  URL to check
 @returns YES if there was a code, NO if there wasn't.
 */
- (BOOL)getCodeFromURL:(NSURL*)url;

@end
