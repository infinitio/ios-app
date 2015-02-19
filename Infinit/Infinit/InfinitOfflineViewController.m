//
//  InfinitOfflineViewController.m
//  Infinit
//
//  Created by Christopher Crone on 18/02/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitOfflineViewController.h"
#import "InfinitTabBarController.h"

#import <Gap/InfinitConnectionManager.h>

@interface InfinitOfflineViewController () <InfinitOfflineOverlayProtocol>

@end

@implementation InfinitOfflineViewController

- (void)viewWillAppear:(BOOL)animated
{
  InfinitConnectionManager* manager = [InfinitConnectionManager sharedInstance];
  _current_status = manager.connected;
  if (!manager.connected && !manager.was_logged_in)
    [self showOfflineOverlayAnimated:NO];
  else
    [self hideOfflineOverlayAnimated:NO];
  [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(connectionStatusChanged:)
                                               name:INFINIT_CONNECTION_STATUS_CHANGE
                                             object:nil];
  [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
  [super viewWillDisappear:animated];
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Connection Status Change

- (void)connectionStatusChanged:(NSNotification*)notification
{
  InfinitConnectionStatus* connection_status = notification.object;
  if (connection_status.status)
  {
    [self performSelectorOnMainThread:@selector(setConnectionStatus:)
                           withObject:@YES
                        waitUntilDone:NO];
  }
  else
  {
    [self performSelectorOnMainThread:@selector(setConnectionStatus:)
                           withObject:@NO
                        waitUntilDone:NO];
  }
}

- (void)setConnectionStatus:(NSNumber*)status_num
{
  BOOL status = status_num.boolValue;
  if (self.current_status == status)
    return;
  _current_status = status;
  if (status)
    [self hideOfflineOverlayAnimated:YES];
  [self statusChangedTo:status];
}

#pragma mark - Offline Overlay

- (NSArray*)horizonalConstraints
{
  NSDictionary* views = @{@"view": self.offline_overlay};
  return [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[view]|"
                                                 options:0
                                                 metrics:nil
                                                   views:views];
}

- (NSArray*)verticalConstraints
{
  NSDictionary* views = @{@"view": self.offline_overlay};
  return [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[view]|"
                                                 options:0
                                                 metrics:nil
                                                   views:views];
}

- (void)showOfflineOverlayAnimated:(BOOL)animated
{
  if (self.showing_offline)
    return;
  _showing_offline = YES;
  if (self.offline_overlay == nil)
  {
    UINib* offline_nib = [UINib nibWithNibName:NSStringFromClass(InfinitOfflineOverlay.class)
                                        bundle:nil];
    _offline_overlay = [[offline_nib instantiateWithOwner:self options:nil] firstObject];
    self.offline_overlay.delegate = self;
    self.offline_overlay.translatesAutoresizingMaskIntoConstraints = NO;
    self.offline_overlay.alpha = 0.0f;
    self.offline_overlay.dark = self.dark;
  }
  [self.view addSubview:self.offline_overlay];
  [self.view addConstraints:[self horizonalConstraints]];
  [self.view addConstraints:[self verticalConstraints]];
  [self.view bringSubviewToFront:self.offline_overlay];
  [UIView animateWithDuration:animated ? 0.2f : 0.0f
                   animations:^
  {
    self.offline_overlay.alpha = 1.0f;
    [self.navigationController setNavigationBarHidden:YES animated:YES];
  } completion:^(BOOL finished)
  {
    if (!finished)
      self.offline_overlay.alpha = 1.0f;
  }];
}

- (void)hideOfflineOverlayAnimated:(BOOL)animated
{
  if (!self.showing_offline)
    return;
  _showing_offline = NO;
  [UIView animateWithDuration:animated ? 0.2f : 0.0f
                   animations:^
   {
     self.offline_overlay.alpha = 0.0f;
     [self.navigationController setNavigationBarHidden:NO animated:YES];
   } completion:^(BOOL finished)
   {
     if (!finished)
       self.offline_overlay.alpha = 0.0f;
     [self.offline_overlay removeFromSuperview];
   }];
}

#pragma mark - Status Change

- (void)statusChangedTo:(BOOL)status
{
  // Defaults to doing nothing.
}

#pragma mark - Button Handling

- (void)filesButtonTapped
{
  // Defaults to doing nothing.
}

- (void)offlineOverlayfilesButtonTapped:(InfinitOfflineOverlay*)sender
{
  [self filesButtonTapped];
  [((InfinitTabBarController*)self.tabBarController) showFilesScreen];
}

@end
