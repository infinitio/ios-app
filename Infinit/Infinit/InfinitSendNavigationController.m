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

@interface InfinitSendNavigationController () <UINavigationControllerDelegate>

@end

@implementation InfinitSendNavigationController

- (void)viewWillAppear:(BOOL)animated
{
  self.delegate = self;
  [self resetSendViews];
  [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
  self.delegate = nil;
  [(InfinitTabBarController*)self.tabBarController setTabBarHidden:NO
                                                          animated:animated 
                                                         withDelay:0.4f];
  [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
  [self popToRootViewControllerAnimated:NO];
  [super viewDidDisappear:animated];
  _recipient = nil;
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

- (void)navigationController:(UINavigationController*)navigationController
      willShowViewController:(UIViewController*)viewController
                    animated:(BOOL)animated;
{
  if (self.recipient != nil && [viewController isKindOfClass:InfinitSendRecipientsController.class])
  {
    InfinitSendRecipientsController* controller = (InfinitSendRecipientsController*)viewController;
    controller.recipient = self.recipient;
  }
}

@end
