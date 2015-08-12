//
//  InfinitPortraitNavigationController.m
//  Infinit
//
//  Created by Christopher Crone on 27/01/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitPortraitNavigationController.h"

@interface InfinitPortraitNavigationController ()

@end

@implementation InfinitPortraitNavigationController

#pragma mark - Rotation

- (BOOL)shouldAutorotate
{
  return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
  return UIInterfaceOrientationMaskPortrait;
}

- (void)viewWillAppear:(BOOL)animated
{
  UIDeviceOrientation orientation =
    [[[UIDevice currentDevice] valueForKey:@"orientation"] integerValue];
  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone &&
      orientation != UIDeviceOrientationPortrait)
  {
    [super viewWillAppear:NO];
    [UIView setAnimationsEnabled:NO];
    [[UIDevice currentDevice] setValue:[NSNumber numberWithInt:UIDeviceOrientationPortrait]
                                forKey:@"orientation"];
  }
  else
  {
    [super viewWillAppear:animated];
  }
}

- (void)viewDidAppear:(BOOL)animated
{
  UIDeviceOrientation orientation =
    [[[UIDevice currentDevice] valueForKey:@"orientation"] integerValue];
  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone &&
      orientation != UIDeviceOrientationPortrait)
  {
    [super viewDidAppear:NO];
  }
  else
  {
    [super viewDidAppear:animated];
  }
  [UIView setAnimationsEnabled:YES];
}

@end
