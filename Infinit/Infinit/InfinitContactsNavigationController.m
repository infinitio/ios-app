//
//  InfinitContactsNavigationController.m
//  Infinit
//
//  Created by Christopher Crone on 02/02/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitContactsNavigationController.h"

#import <Gap/InfinitColor.h>

@interface InfinitContactsNavigationController ()

@end

@implementation InfinitContactsNavigationController

- (void)viewDidLoad
{
  [super viewDidLoad];
  self.navigationBar.tintColor = [InfinitColor colorFromPalette:InfinitPaletteColorBurntSienna];
}

- (void)viewWillAppear:(BOOL)animated
{
  [self popToRootViewControllerAnimated:NO];
  [super viewWillAppear:animated];
}

@end
