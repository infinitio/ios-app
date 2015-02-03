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

- (void)viewDidLoad
{
  [super viewDidLoad];
  self.navigationItem.titleView =
    [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icon-logo-red"]];
  [self.navigationController.navigationBar setBackgroundImage:[[UIImage alloc] init]
                                                forBarMetrics:UIBarMetricsDefault];
  self.navigationController.navigationBar.shadowImage = [[UIImage alloc] init];
}

- (void)viewWillDisappear:(BOOL)animated
{
  [self.activity stopAnimating];
  [super viewWillDisappear:animated];
}

@end
