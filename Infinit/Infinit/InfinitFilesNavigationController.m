//
//  InfinitFilesNavigationController.m
//  Infinit
//
//  Created by Christopher Crone on 31/01/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitFilesNavigationController.h"

#import "InfinitFilesMultipleViewController.h"

@interface InfinitFilesNavigationController ()

@end

@implementation InfinitFilesNavigationController

- (void)viewWillAppear:(BOOL)animated
{
  if ([self.visibleViewController isKindOfClass:InfinitFilesMultipleViewController.class])
    [self popToRootViewControllerAnimated:animated];
  [super viewWillAppear:animated];
}

@end
