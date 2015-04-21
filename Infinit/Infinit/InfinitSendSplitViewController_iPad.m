//
//  InfinitSendSplitViewController_iPad.m
//  Infinit
//
//  Created by Christopher Crone on 21/04/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitSendSplitViewController_iPad.h"

#import "InfinitHostDevice.h"
#import "InfinitSendGalleryController.h"
#import "InfinitSendRecipientsController.h"

@interface InfinitSendSplitViewController_iPad () <InfinitSendGalleryProtocol>

@property (nonatomic, strong) InfinitSendGalleryController* gallery_controller;
@property (nonatomic, strong) InfinitSendRecipientsController* recipient_controller;

@end

@implementation InfinitSendSplitViewController_iPad

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

- (void)viewWillAppear:(BOOL)animated
{
  [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleLightContent;
  [self.recipient_controller resetView];
  [self.gallery_controller resetView];
  [self.viewControllers[0] pushViewController:self.recipient_controller animated:NO];
  [self.viewControllers[1] pushViewController:self.gallery_controller animated:NO];
  [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
  [super viewWillDisappear:animated];
  [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleDefault;
}

#pragma mark - Gallery Protocol

- (void)sendGalleryView:(InfinitSendGalleryController*)sender
         selectedAssets:(NSArray*)assets
{
  self.recipient_controller.assets = assets;
}

#pragma mark - Helpers

- (InfinitSendGalleryController*)gallery_controller
{
  if (_gallery_controller == nil)
  {
    _gallery_controller =
      [self.storyboard instantiateViewControllerWithIdentifier:@"send_gallery_controller_id"];
    _gallery_controller.delegate = self;
  }
  return _gallery_controller;
}

- (InfinitSendRecipientsController*)recipient_controller
{
  if (_recipient_controller == nil)
  {
    _recipient_controller =
      [self.storyboard instantiateViewControllerWithIdentifier:@"send_recipients_controller"];
  }
  return _recipient_controller;
}

- (UIStoryboard*)storyboard
{
  return [UIStoryboard storyboardWithName:@"Main" bundle:nil];
}

@end
