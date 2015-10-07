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

#import <Gap/InfinitColor.h>

@interface InfinitSendNavigationController () <UINavigationControllerDelegate>

@end

@implementation InfinitSendNavigationController

- (void)viewDidLoad
{
  [super viewDidLoad];
  Class this_class = InfinitSendNavigationController.class;
    [UINavigationBar appearanceWhenContainedIn:this_class, nil].tintColor = [UIColor whiteColor];
  UIImage* back_image = [UIImage imageNamed:@"icon-back-white"];
  self.navigationController.navigationBar.backIndicatorImage = back_image;
  self.navigationController.navigationBar.backIndicatorTransitionMaskImage = back_image;
  self.navigationItem.backBarButtonItem =
    [[UIBarButtonItem alloc] initWithImage:back_image
                                     style:UIBarButtonItemStylePlain
                                    target:nil
                                    action:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
  if (!self.smsing)
  {
    self.delegate = self;
    [self resetSendViews];
  }
  [super viewWillAppear:animated];
  if (!self.tabBarController.tabBar.hidden)
    [(InfinitTabBarController*)self.tabBarController setTabBarHidden:YES animated:NO];
}

- (void)viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];
  if (![UIApplication sharedApplication].statusBarHidden)
    [UIApplication sharedApplication].statusBarHidden = YES;
}

- (void)viewWillDisappear:(BOOL)animated
{
  if (!self.smsing)
  {
    self.delegate = nil;
    [(InfinitTabBarController*)self.tabBarController setTabBarHidden:NO
                                                            animated:animated 
                                                           withDelay:0.4f];
  }
  [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
  if (!self.smsing)
  {
    [self popToRootViewControllerAnimated:NO];
    _recipient = nil;
  }
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
