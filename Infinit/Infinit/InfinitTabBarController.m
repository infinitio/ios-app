//
//  InfinitTabBarController.m
//  Infinit
//
//  Created by Michael Dee on 11/27/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import "InfinitTabBarController.h"

@interface InfinitTabBarController ()

@end

@implementation InfinitTabBarController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.tabBar.tintColor = [UIColor cyanColor];
    
    //Check for the badge items here.
    _badgeLabel = [[TabBarBadgeLabel alloc] initWithFrame:CGRectMake(0, 0, 16, 16)
                                                                    onItem:0
                                                                 withBadge:4];
    [self.tabBar addSubview:_badgeLabel];
    
}





@end
