//
//  InfinitLoggingInViewController.m
//  Infinit
//
//  Created by Christopher Crone on 19/01/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitLoggingInViewController.h"

@interface InfinitLoggingInViewController ()

@property (nonatomic, weak) IBOutlet UIActivityIndicatorView* activity;

@end

@implementation InfinitLoggingInViewController

- (BOOL)shouldAutorotate
{
  return YES;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  self.navigationItem.titleView =
    [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icon-logo-red"]];
  [self.navigationController.navigationBar setBackgroundImage:[[UIImage alloc] init]
                                                forBarMetrics:UIBarMetricsDefault];
  self.navigationController.navigationBar.shadowImage = [[UIImage alloc] init];
}

- (void)viewWillAppear:(BOOL)animated
{
  [[UIApplication sharedApplication] setStatusBarHidden:NO];
  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
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
  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
  {
    [super viewDidAppear:NO];
    [UIView setAnimationsEnabled:YES];
  }
  else
  {
    [super viewDidAppear:animated];
  }
}

- (void)viewWillDisappear:(BOOL)animated
{
  [self.activity stopAnimating];
  [super viewWillDisappear:animated];
}

@end
