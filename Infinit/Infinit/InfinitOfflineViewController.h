//
//  InfinitOfflineViewController.h
//  Infinit
//
//  Created by Christopher Crone on 18/02/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "InfinitOfflineOverlay.h"

@interface InfinitOfflineViewController : UIViewController

@property (nonatomic, readonly) BOOL current_status;
@property (nonatomic, readwrite) BOOL dark;
@property (nonatomic, strong, readonly) InfinitOfflineOverlay* offline_overlay;
@property (nonatomic, readonly) BOOL showing_offline;

// Constraints used for positioning the offline overlay.
// Override to use constraints other than aligned to edges of view.
- (NSArray*)horizonalConstraints;
- (NSArray*)verticalConstraints;

// Called to alert those who inherit from this controller that the status changed.
- (void)statusChangedTo:(BOOL)status;

/// Called just before changing to files view.
- (void)filesButtonTapped;

@end
