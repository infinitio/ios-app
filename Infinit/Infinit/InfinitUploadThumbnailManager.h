//
//  InfinitUploadThumbnailManager.h
//  Infinit
//
//  Created by Christopher Crone on 04/03/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Gap/InfinitPeerTransaction.h>

@interface InfinitUploadThumbnailManager : NSObject

+ (instancetype)sharedInstance;

- (BOOL)areThumbnailsForTransaction:(InfinitPeerTransaction*)transaction;

- (void)generateThumbnailsForAssets:(NSArray*)assets
               forTransactionWithId:(NSNumber*)id_;

- (void)generateThumbnailsForFiles:(NSArray*)files
              forTransactionWithId:(NSNumber*)id_;

- (void)removeThumbnailsForTransaction:(InfinitPeerTransaction*)transaction;

- (NSArray*)thumbnailsForTransaction:(InfinitPeerTransaction*)transaction;

@end
