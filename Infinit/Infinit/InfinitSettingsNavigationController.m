//
//  InfinitSettingsNavigationController.m
//  Infinit
//
//  Created by Christopher Crone on 11/03/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitSettingsNavigationController.h"

@interface InfinitSettingsNavigationController ()

@end

@implementation InfinitSettingsNavigationController

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  [self popToRootViewControllerAnimated:NO];
}

@end
