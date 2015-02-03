//
//  InfinitContactsNavigationController.m
//  Infinit
//
//  Created by Christopher Crone on 02/02/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitContactsNavigationController.h"

@interface InfinitContactsNavigationController ()

@end

@implementation InfinitContactsNavigationController

- (void)viewWillAppear:(BOOL)animated
{
  [self popToRootViewControllerAnimated:NO];
  [super viewWillAppear:animated];
}

@end
