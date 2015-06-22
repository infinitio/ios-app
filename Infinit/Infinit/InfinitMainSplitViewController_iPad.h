//
//  InfinitMainSplitViewController_iPad.h
//  Infinit
//
//  Created by Christopher Crone on 15/04/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "InfinitFolderModel.h"

@class InfinitManagedFiles;

@interface InfinitMainSplitViewController_iPad : UISplitViewController

- (void)showSendGalleryView;
- (void)showSendViewForManagedFiles:(InfinitManagedFiles*)managed_files;
- (void)showViewForFolder:(InfinitFolderModel*)folder;

@end
