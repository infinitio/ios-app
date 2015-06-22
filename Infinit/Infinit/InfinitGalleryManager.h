//
//  InfinitGalleryManager.h
//  Infinit
//
//  Created by Christopher Crone on 17/04/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface InfinitGalleryManager : NSObject

@property (nonatomic, readwrite) BOOL autosave;

+ (instancetype)sharedInstance;

+ (void)saveToGallery:(NSArray*)paths;

@end
