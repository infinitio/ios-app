//
//  InfinitContactsViewController.h
//  Infinit
//
//  Created by Christopher Crone on 31/01/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "InfinitOfflineViewController.h"

@interface InfinitContactsViewController : InfinitOfflineViewController

@property BOOL invitation_mode;

- (void)tabIconTap;

@end
