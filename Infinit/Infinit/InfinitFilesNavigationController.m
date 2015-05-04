//
//  InfinitFilesNavigationController.m
//  Infinit
//
//  Created by Christopher Crone on 31/01/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitFilesNavigationController.h"

#import "InfinitFilesMultipleViewController.h"
#import "InfinitSendRecipientsController.h"

#import <Gap/InfinitColor.h>

@interface InfinitFilesNavigationController ()

@end

@implementation InfinitFilesNavigationController

- (void)viewDidLoad
{
  [super viewDidLoad];
  self.navigationBar.tintColor = [InfinitColor colorFromPalette:InfinitPaletteColorBurntSienna];
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

- (void)pushViewController:(UIViewController*)viewController
                  animated:(BOOL)animated
{
  [super pushViewController:viewController animated:animated];
  if ([viewController isKindOfClass:InfinitSendRecipientsController.class])
    self.navigationBar.tintColor = [UIColor whiteColor];
  else
    self.navigationBar.tintColor = [InfinitColor colorFromPalette:InfinitPaletteColorBurntSienna];
}

- (UIViewController*)popViewControllerAnimated:(BOOL)animated
{
  self.navigationBar.tintColor = [InfinitColor colorFromPalette:InfinitPaletteColorBurntSienna];
  return [super popViewControllerAnimated:animated];
}

@end
