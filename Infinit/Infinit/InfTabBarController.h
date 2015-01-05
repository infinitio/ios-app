//
//  InfTabBarController.h
//  Infinit
//
//  Created by Michael Dee on 6/27/14.
//  Copyright (c) 2014 Michael Dee. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TabBarBadgeLabel.h"


@interface InfTabBarController : UITabBarController <UITabBarControllerDelegate>

@property (strong, nonatomic) TabBarBadgeLabel* badge_label;


@end
