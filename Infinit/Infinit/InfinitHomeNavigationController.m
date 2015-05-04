//
//  InfinitHomeNavigationController.m
//  Infinit
//
//  Created by Christopher Crone on 26/02/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitHomeNavigationController.h"

#import "InfinitFilesViewController.h"
#import "InfinitFilesMultipleViewController.h"
#import "InfinitSendRecipientsController.h"

#import <Gap/InfinitColor.h>

@interface InfinitHomeNavigationController ()

@end

@implementation InfinitHomeNavigationController

- (void)viewWillAppear:(BOOL)animated
{
  [self popToRootViewControllerAnimated:NO];
  [super viewWillAppear:animated];
}

- (void)pushViewController:(UIViewController*)viewController
                  animated:(BOOL)animated
{
  [super pushViewController:viewController animated:animated];
  if ([viewController isKindOfClass:InfinitSendRecipientsController.class])
  {
    self.navigationBar.tintColor = [UIColor whiteColor];
  }
  else if ([viewController isKindOfClass:InfinitFilesViewController.class] ||
           [viewController isKindOfClass:InfinitFilesMultipleViewController.class])
  {
    self.navigationBar.tintColor = [InfinitColor colorFromPalette:InfinitPaletteColorBurntSienna];
  }
}

- (UIViewController*)popViewControllerAnimated:(BOOL)animated
{
  self.navigationBar.barTintColor = [InfinitColor colorFromPalette:InfinitPaletteColorLightGray];
  return [super popViewControllerAnimated:animated];
}

@end
