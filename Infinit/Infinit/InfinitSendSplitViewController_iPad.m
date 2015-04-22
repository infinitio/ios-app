//
//  InfinitSendSplitViewController_iPad.m
//  Infinit
//
//  Created by Christopher Crone on 21/04/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitSendSplitViewController_iPad.h"

#import "InfinitAccessGalleryView.h"
#import "InfinitHostDevice.h"
#import "InfinitSendGalleryController.h"
#import "InfinitSendRecipientsController.h"

@import AssetsLibrary;

@interface InfinitSendSplitViewController_iPad () <InfinitSendGalleryProtocol,
                                                   UIAlertViewDelegate>

@property (nonatomic, strong) InfinitAccessGalleryView* access_gallery_view;
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
  UINavigationController* master_nav_controller = self.viewControllers[0];
  UINavigationController* detail_nav_controller = self.viewControllers[1];
  [master_nav_controller pushViewController:self.recipient_controller animated:NO];
  if ([ALAssetsLibrary authorizationStatus] == ALAuthorizationStatusNotDetermined)
  {
    self.access_gallery_view.translatesAutoresizingMaskIntoConstraints = NO;
    [detail_nav_controller.view addSubview:self.access_gallery_view];
    NSDictionary* views = @{@"view": self.access_gallery_view};
    NSMutableArray* constraints =
      [NSMutableArray arrayWithArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[view]|"
                                                                             options:0
                                                                             metrics:nil
                                                                               views:views]];
    [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[view]|"
                                                                             options:0 
                                                                             metrics:nil
                                                                               views:views]];
    [detail_nav_controller.view addConstraints:constraints];
  }
  else if ([ALAssetsLibrary authorizationStatus] == ALAuthorizationStatusAuthorized)
  {
    [detail_nav_controller pushViewController:self.gallery_controller animated:NO];
  }
  else
  {
    NSString* title = NSLocalizedString(@"No access to gallery.", nil);
    NSString* message =
      NSLocalizedString(@"Infinit requires access to your gallery to send photos and videos.", nil);
    UIAlertView* alert = nil;
    if ([InfinitHostDevice iOSVersion] >= 8.0)
    {
      alert = [[UIAlertView alloc] initWithTitle:title
                                         message:message
                                        delegate:self
                               cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                               otherButtonTitles:NSLocalizedString(@"Settings", nil), nil];
    }
    else
    {
      alert = [[UIAlertView alloc] initWithTitle:title
                                         message:message
                                        delegate:self
                               cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                               otherButtonTitles:nil];
    }
    [alert show];
  }
  [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
  [super viewWillDisappear:animated];
  [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleDefault;
}

#pragma mark - Alert Delegate

- (void)alertView:(UIAlertView*)alertView
clickedButtonAtIndex:(NSInteger)buttonIndex
{
  if (alertView.cancelButtonIndex == buttonIndex)
    return;
  NSURL* settings_url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
  [[UIApplication sharedApplication] openURL:settings_url];
  [self dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark - Gallery Protocol

- (void)sendGalleryView:(InfinitSendGalleryController*)sender
         selectedAssets:(NSArray*)assets
{
  self.recipient_controller.assets = assets;
}

#pragma mark - Helpers

- (InfinitAccessGalleryView*)access_gallery_view
{
  if (_access_gallery_view == nil)
  {
    UINib* nib = [UINib nibWithNibName:@"InfinitAccessGalleryView" bundle:nil];
    _access_gallery_view = [nib instantiateWithOwner:self options:nil].firstObject;
  }
  return _access_gallery_view;
}

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
