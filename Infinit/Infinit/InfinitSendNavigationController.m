//
//  InfinitSendNavigationController.m
//  Infinit
//
//  Created by Christopher Crone on 19/01/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitSendNavigationController.h"

#import "InfinitSendGalleryController.h"
#import "InfinitSendRecipientsController.h"
#import "InfinitTabBarController.h"

@interface InfinitSendNavigationController ()

@end

@implementation InfinitSendNavigationController

- (void)viewWillAppear:(BOOL)animated
{
  [self resetSendViews];
  [[UIApplication sharedApplication] setStatusBarHidden:YES
                                          withAnimation:UIStatusBarAnimationFade];
  [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
  [[UIApplication sharedApplication] setStatusBarHidden:NO
                                          withAnimation:UIStatusBarAnimationSlide];
  [(InfinitTabBarController*)self.tabBarController setTabBarHidden:NO animated:animated];
  [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
  [self popToRootViewControllerAnimated:NO];
  [super viewDidDisappear:animated];
}

- (void)resetSendViews
{
  for (UIViewController* controller in self.viewControllers)
  {
    if ([controller isKindOfClass:InfinitSendGalleryController.class])
    {
      [(InfinitSendGalleryController*)controller resetView];
    }
    else if ([controller isKindOfClass:InfinitSendRecipientsController.class])
    {
      [(InfinitSendRecipientsController*)controller resetView];
    }
  }
}

@end
