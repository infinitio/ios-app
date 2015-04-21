//
//  InfinitSendGalleryController.h
//  Infinit
//
//  Created by Michael Dee on 12/17/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "InfinitOfflineViewController.h"

@protocol InfinitSendGalleryProtocol;

@interface InfinitSendGalleryController : InfinitOfflineViewController

@property (nonatomic, readwrite, weak) id<InfinitSendGalleryProtocol> delegate;

- (void)resetView;

@end

@protocol InfinitSendGalleryProtocol <NSObject>

- (void)sendGalleryView:(InfinitSendGalleryController*)sender
         selectedAssets:(NSArray*)assets;

@end
