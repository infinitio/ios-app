//
//  InfinitTabBarController_iPad.m
//  Infinit
//
//  Created by Christopher Crone on 15/04/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitTabBarController_iPad.h"

#import "InfinitColor.h"

#import <Gap/InfinitPeerTransactionManager.h>

typedef NS_ENUM(NSUInteger, InfinitTabBarIndex)
{
  InfinitTabBarIndexHome = 0,
  InfinitTabBarIndexSettings,
};

@interface InfinitTabBarController_iPad () <UITabBarControllerDelegate>

@property (nonatomic, readonly) UIView* selection_indicator;

@end

@implementation InfinitTabBarController_iPad

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
  [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
  [self selectorToPosition:self.selectedIndex];
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  self.delegate = self;
  UIViewController* home_controller
    = [self.storyboard instantiateViewControllerWithIdentifier:@"home_nav_controller"];
  UIViewController* settings_controller
    = [self.storyboard instantiateViewControllerWithIdentifier:@"settings_nav_controller"];
  self.viewControllers = @[home_controller, settings_controller];
  for (NSUInteger index = 0; index < self.tabBar.items.count; index++)
  {
    [self.tabBar.items[index] setImageInsets:UIEdgeInsetsMake(5.0f, 0.0f, -5.0f, 0.0f)];
    [self.tabBar.items[index] setImage:[self imageForTabBarItem:index selected:NO]];
    [self.tabBar.items[index] setSelectedImage:[self imageForTabBarItem:index selected:YES]];
  }
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(peerTransactionUpdated:)
                                               name:INFINIT_NEW_PEER_TRANSACTION_NOTIFICATION
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(peerTransactionUpdated:)
                                               name:INFINIT_PEER_TRANSACTION_STATUS_NOTIFICATION
                                             object:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];
  static dispatch_once_t first_appear;
  dispatch_once(&first_appear, ^
  {
    self.tabBar.barTintColor = [UIColor whiteColor];
    self.tabBar.shadowImage = [[UIImage alloc] init];
    CGFloat width = self.tabBar.frame.size.width;
    UIView* shadow_line = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, width, 1.0f)];
    shadow_line.backgroundColor = [InfinitColor colorWithGray:216.0f];
    [self.tabBar addSubview:shadow_line];
    NSInteger count = self.viewControllers.count;
    _selection_indicator =
      [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, width / count, 1.0f)];
    self.selection_indicator.backgroundColor =
    [InfinitColor colorFromPalette:InfinitPaletteColorBurntSienna];
    [self.tabBar addSubview:self.selection_indicator];
    self.view.clipsToBounds = YES;
  });
}

#pragma mark - Transaction Updates

- (void)peerTransactionUpdated:(NSNotification*)notification
{
  [self updateHomeBadge];
}

- (void)updateHomeBadge
{
  NSArray* transactions = [[InfinitPeerTransactionManager sharedInstance] transactions];
  NSUInteger count = 0;
  for (InfinitPeerTransaction* transaction in transactions)
  {
    if (transaction.receivable)
      count++;
  }
  NSString* badge;
  if (count == 0)
    badge = nil;
  else if (count < 100)
    badge = [NSString stringWithFormat:@"%lu", (unsigned long)count];
  else
    badge = @"+";
  [self.tabBar.items[InfinitTabBarIndexHome] setBadgeValue:badge];
}

#pragma mark - UITabBarController

- (void)setSelectedIndex:(NSUInteger)selectedIndex
{
  if (selectedIndex == self.selectedIndex)
    return;
  [super setSelectedIndex:selectedIndex];
  [self selectorToPosition:selectedIndex];
}

- (BOOL)tabBarController:(UITabBarController*)tabBarController
shouldSelectViewController:(UIViewController*)viewController
{
  [self selectorToPosition:[self.viewControllers indexOfObject:viewController]];
  return YES;
}

#pragma mark - Tab Selector

- (void)selectorToPosition:(NSInteger)position
{
  NSUInteger count = self.viewControllers.count;
  CGFloat width = self.tabBar.frame.size.width;
  self.selection_indicator.frame = CGRectMake(position == 0 ? 0.0f : width / (count * position),
                                              0.0f,
                                              width / count,
                                              1.0f);
}

#pragma mark - Helpers

- (UIImage*)imageForTabBarItem:(InfinitTabBarIndex)index
                      selected:(BOOL)selected
{
  NSString* image_name = nil;
  switch (index)
  {
    case InfinitTabBarIndexHome:
      image_name = @"icon-tab-home";
      break;
    case InfinitTabBarIndexSettings:
      image_name = @"icon-tab-settings";
      break;

    default:
      return nil;
  }
  if (selected)
    image_name = [image_name stringByAppendingString:@"-active"];
  return [[UIImage imageNamed:image_name]imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
}

@end
