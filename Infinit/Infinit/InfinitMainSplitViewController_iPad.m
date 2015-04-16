//
//  InfinitMainSplitViewController_iPad.m
//  Infinit
//
//  Created by Christopher Crone on 15/04/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitMainSplitViewController_iPad.h"

#import "InfinitHostDevice.h"
#import "InfinitHomeViewController.h"

@interface InfinitMainSplitViewController_iPad ()

@property (nonatomic, strong) UITabBarController* tab_controller;

@end

@implementation InfinitMainSplitViewController_iPad

#pragma mark - UISplitViewController


- (BOOL)splitViewController:(UISplitViewController*)svc
   shouldHideViewController:(UIViewController*)vc
              inOrientation:(UIInterfaceOrientation)orientation
{
  return NO;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  if ([InfinitHostDevice iOSVersion] >= 8.0)
    self.preferredDisplayMode = UISplitViewControllerDisplayModeAllVisible;
}

@end
