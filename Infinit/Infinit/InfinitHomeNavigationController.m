//
//  InfinitHomeNavigationController.m
//  Infinit
//
//  Created by Christopher Crone on 26/02/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitHomeNavigationController.h"

@interface InfinitHomeNavigationController ()

@end

@implementation InfinitHomeNavigationController

- (void)viewWillAppear:(BOOL)animated
{
  [self popToRootViewControllerAnimated:NO];
  [super viewWillAppear:animated];
}

@end
