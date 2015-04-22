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
#import "InfinitMetricsManager.h"
#import "InfinitSendGalleryController.h"
#import "InfinitSendRecipientsController.h"

@import AssetsLibrary;

@interface InfinitSendSplitViewController_iPad () <InfinitSendGalleryProtocol,
                                                   UIAlertViewDelegate>

@property (nonatomic, readonly) UINavigationController* detail_controller;
@property (nonatomic, readonly) UINavigationController* master_controller;

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
  [self.master_controller pushViewController:self.recipient_controller animated:NO];
  if ([ALAssetsLibrary authorizationStatus] == ALAuthorizationStatusNotDetermined)
  {
    self.access_gallery_view.translatesAutoresizingMaskIntoConstraints = NO;
    [self.detail_controller.view addSubview:self.access_gallery_view];
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
    [self.detail_controller.view addConstraints:constraints];
  }
  else if ([ALAssetsLibrary authorizationStatus] == ALAuthorizationStatusAuthorized)
  {
    [self.detail_controller pushViewController:self.gallery_controller animated:NO];
  }
  else
  {
    [self noGalleryAccessPopup];
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
  if (alertView.cancelButtonIndex != buttonIndex)
  {
    NSURL* settings_url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
    [[UIApplication sharedApplication] openURL:settings_url];
  }
  [self dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark - Gallery Protocol

- (void)sendGalleryView:(InfinitSendGalleryController*)sender
         selectedAssets:(NSArray*)assets
{
  self.recipient_controller.assets = assets;
}

#pragma mark - Gallery Access

- (void)noGalleryAccessPopup
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

- (void)accessGallery:(id)sender
{
  self.access_gallery_view.access_button.enabled = NO;
  self.access_gallery_view.access_button.hidden = YES;
  self.access_gallery_view.image_view.hidden = YES;
  NSDictionary* bold_attrs = @{NSFontAttributeName: [UIFont fontWithName:@"HelveticaNeue-Bold"
                                                                    size:20.0f],
                               NSForegroundColorAttributeName: [UIColor whiteColor]};
  self.access_gallery_view.message_label.text =
    NSLocalizedString(@"Tap 'OK' to select your photos and videos.", nil);
  NSMutableAttributedString* res = [self.access_gallery_view.message_label.attributedText mutableCopy];
  NSRange bold_range = [res.string rangeOfString:@"OK"];
  [res setAttributes:bold_attrs range:bold_range];
  self.access_gallery_view.message_label.attributedText = res;
  ALAssetsLibrary* library = [[ALAssetsLibrary alloc] init];
  [library enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos
                         usingBlock:^(ALAssetsGroup* group, BOOL* stop)
   {
     static dispatch_once_t _gallery_access = 0;
     dispatch_once(&_gallery_access, ^
     {
       [InfinitMetricsManager sendMetric:InfinitUIEventAccessGallery
                                  method:InfinitUIMethodYes];
       [self.access_gallery_view removeFromSuperview];
       _access_gallery_view = nil;
       [self.detail_controller pushViewController:self.gallery_controller animated:NO];
     });
     *stop = YES;
   } failureBlock:^(NSError* error)
   {
     [self noGalleryAccessPopup];
     [InfinitMetricsManager sendMetric:InfinitUIEventAccessGallery
                                method:InfinitUIMethodNo];
     [self.access_gallery_view removeFromSuperview];
     if (error.code == ALAssetsLibraryAccessUserDeniedError)
     {
       NSLog(@"user denied access, code: %li", (long)error.code);
     }
     else
     {
       NSLog(@"Other error code: %li", (long)error.code);
     }
     _access_gallery_view = nil;
   }];
}

#pragma mark - Helpers

- (UINavigationController*)detail_controller
{
  return self.viewControllers[1];
}

- (UINavigationController*)master_controller
{
  return self.viewControllers[0];
}

- (InfinitAccessGalleryView*)access_gallery_view
{
  if (_access_gallery_view == nil)
  {
    UINib* nib = [UINib nibWithNibName:@"InfinitAccessGalleryView" bundle:nil];
    _access_gallery_view = [nib instantiateWithOwner:self options:nil].firstObject;
    [_access_gallery_view.access_button addTarget:self
                                           action:@selector(accessGallery:)
                                 forControlEvents:UIControlEventTouchUpInside];
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
      [self.storyboard instantiateViewControllerWithIdentifier:@"send_recipients_controller_id"];
  }
  return _recipient_controller;
}

- (UIStoryboard*)storyboard
{
  return [UIStoryboard storyboardWithName:@"Main" bundle:nil];
}

@end
