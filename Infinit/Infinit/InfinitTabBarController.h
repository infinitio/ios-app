//
//  InfTabBarController.h
//  Infinit
//
//  Created by Michael Dee on 6/27/14.
//  Copyright (c) 2014 Michael Dee. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "InfinitContact.h"

@interface InfinitTabBarController : UITabBarController

- (void)lastSelectedIndex;
- (void)setTabBarHidden:(BOOL)hidden animated:(BOOL)animate;
- (void)showFilesScreen;
- (void)showMainScreen;
- (void)showSendScreenWithContact:(InfinitContact*)contact;
- (void)showWelcomeScreen;

@end
