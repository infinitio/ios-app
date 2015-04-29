//
//  InfinitFilesNavigationController.m
//  Infinit
//
//  Created by Christopher Crone on 31/01/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitFilesNavigationController.h"

#import "InfinitFilesMultipleViewController.h"

#import <Gap/InfinitColor.h>

@interface InfinitFilesNavigationController ()

@end

@implementation InfinitFilesNavigationController

- (void)viewDidLoad
{
  [super viewDidLoad];
  Class this_class = InfinitFilesNavigationController.class;
  [UINavigationBar appearanceWhenContainedIn:this_class, nil].tintColor =
    [InfinitColor colorFromPalette:InfinitPaletteColorBurntSienna];
}

- (void)viewWillAppear:(BOOL)animated
{
  _previewing = NO;
  if ([self.visibleViewController isKindOfClass:InfinitFilesMultipleViewController.class])
    [self popToRootViewControllerAnimated:animated];
  [super viewWillAppear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
  if (!self.previewing)
    [self popToRootViewControllerAnimated:NO];
  [super viewDidDisappear:animated];
}

@end
