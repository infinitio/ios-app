//
//  InfTabBarController.h
//  Infinit
//
//  Created by Michael Dee on 6/27/14.
//  Copyright (c) 2014 Michael Dee. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface InfinitTabBarController : UITabBarController <UITabBarControllerDelegate>

- (void)lastSelectedIndex;
- (void)setTabBarHidden:(BOOL)hidden animated:(BOOL)animate;
- (void)showMainScreen;
- (void)showWelcomeScreen;

@end
