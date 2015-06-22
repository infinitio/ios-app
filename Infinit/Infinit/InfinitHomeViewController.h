//
//  InfinitHomeViewController.h
//  Infinit
//
//  Created by Michael Dee on 12/30/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "InfinitOfflineViewController.h"

@class InfinitManagedFiles;

@interface InfinitHomeViewController : InfinitOfflineViewController

- (void)scrollToTop;

- (void)showRecipientsForManagedFiles:(InfinitManagedFiles*)uuid;
- (void)showRecipientsForLocalFiles:(NSArray*)files;

@end
