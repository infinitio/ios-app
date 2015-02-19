//
//  InfinitOfflineOverlay.h
//  Infinit
//
//  Created by Christopher Crone on 17/02/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol InfinitOfflineOverlayProtocol;

@interface InfinitOfflineOverlay : UIView

@property (nonatomic, weak, readwrite) id<InfinitOfflineOverlayProtocol> delegate;
@property (nonatomic, readwrite) BOOL dark;

@end

@protocol InfinitOfflineOverlayProtocol <NSObject>

- (void)offlineOverlayfilesButtonTapped:(InfinitOfflineOverlay*)sender;

@end
