//
//  InfinitMainSplitViewController_iPad.h
//  Infinit
//
//  Created by Christopher Crone on 15/04/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "InfinitFolderModel.h"

@interface InfinitMainSplitViewController_iPad : UISplitViewController

- (void)showSendViewForFiles:(NSArray*)files;
- (void)showViewForFolder:(InfinitFolderModel*)folder;

@end
