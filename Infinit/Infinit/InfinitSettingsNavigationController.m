//
//  InfinitSettingsNavigationController.m
//  Infinit
//
//  Created by Christopher Crone on 11/03/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitSettingsNavigationController.h"

#import "InfinitSettingsEditProfileViewController.h"

@interface InfinitSettingsNavigationController ()

@property (nonatomic, readwrite) BOOL editing_profile;

@end

@implementation InfinitSettingsNavigationController

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  if (!self.editing_profile)
    [self popToRootViewControllerAnimated:NO];
}

- (void)pushViewController:(UIViewController*)viewController
                  animated:(BOOL)animated
{
  if ([viewController isKindOfClass:InfinitSettingsEditProfileViewController.class]) // iOS 7
  {
    self.editing_profile = YES;
  }
  else if ([viewController isKindOfClass:UINavigationController.class]) // iOS 8
  {
    UINavigationController* nav_controller = (UINavigationController*)viewController;
    if ([nav_controller.topViewController isKindOfClass:InfinitSettingsEditProfileViewController.class])
      self.editing_profile = YES;
  }
  [super pushViewController:viewController animated:animated];
}

- (UIViewController*)popViewControllerAnimated:(BOOL)animated
{
  self.editing_profile = NO;
  return [super popViewControllerAnimated:animated];
}

@end
