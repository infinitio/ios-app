//
//  InfinitMainSplitViewController_iPad.m
//  Infinit
//
//  Created by Christopher Crone on 15/04/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitMainSplitViewController_iPad.h"

#import "InfinitExtensionInfo.h"
#import "InfinitExtensionPopoverController.h"
#import "InfinitFacebookManager.h"
#import "InfinitFilesViewController_iPad.h"
#import "InfinitHostDevice.h"
#import "InfinitSendGalleryController.h"
#import "InfinitSendRecipientsController.h"
#import "InfinitOverlayViewController.h"
#import "InfinitWormhole.h"

#import <FacebookSDK/FacebookSDK.h>
#import <Gap/InfinitConnectionManager.h>
#import <Gap/InfinitTemporaryFileManager.h>

@interface InfinitMainSplitViewController_iPad () <InfinitExtensionPopoverProtocol,
                                                   InfinitOverlayViewControllerProtocol,
                                                   UISplitViewControllerDelegate>

@property (nonatomic, strong) InfinitSendGalleryController* gallery_controller;
@property (nonatomic, strong) InfinitOverlayViewController* overlay_controller;
@property (nonatomic, strong) InfinitSendRecipientsController* recipient_controller;

@property (nonatomic, readonly) NSString* extension_uuid;
@property (nonatomic, strong) InfinitExtensionPopoverController* extension_controller;

@end

@implementation InfinitMainSplitViewController_iPad

- (void)didReceiveMemoryWarning
{
  if (!self.overlay_controller.visible)
  {
    _extension_controller = nil;
    _recipient_controller = nil;
    _overlay_controller = nil;
  }
  [super didReceiveMemoryWarning];
}

- (void)applicationBecameActive
{
  [self handleExtensionFiles];
}

#pragma mark - UISplitViewController

- (BOOL)splitViewController:(UISplitViewController*)svc
   shouldHideViewController:(UIViewController*)vc
              inOrientation:(UIInterfaceOrientation)orientation
{
  return NO;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  self.delegate = self;
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(connectionStatusChanged:)
                                               name:INFINIT_CONNECTION_STATUS_CHANGE
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(applicationBecameActive)
                                               name:UIApplicationDidBecomeActiveNotification
                                             object:nil];
  if ([InfinitHostDevice iOSVersion] >= 8.0)
  {
    self.preferredDisplayMode = UISplitViewControllerDisplayModeAllVisible;
    InfinitWormhole* wormhole = [InfinitWormhole sharedInstance];
    [wormhole registerForWormholeNotification:INFINIT_PING_NOTIFICATION
                                     observer:self
                                     selector:@selector(pingReceived)];
    [wormhole registerForWormholeNotification:INFINIT_EXTENSION_FILES_NOTIFICATION
                                     observer:self
                                     selector:@selector(extensionLocalFilesReceived)];
  }
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];
}

#pragma mark - Connection Handling

- (void)connectionStatusChanged:(NSNotification*)notification
{
  InfinitConnectionStatus* connection_status = notification.object;
  if (!connection_status.status && !connection_status.still_trying)
  {
    if (FBSession.activeSession.state == FBSessionStateCreatedTokenLoaded ||
        FBSession.activeSession.state == FBSessionStateCreatedOpening||
        FBSession.activeSession.state == FBSessionStateOpen ||
        FBSession.activeSession.state == FBSessionStateOpenTokenExtended)
    {
      [[InfinitFacebookManager sharedInstance] cleanSession];
    }
    [self showWelcomeScreen];
  }
  else if (!connection_status.status)
  {
    [self handleOffline];
  }
  else if (connection_status.status)
  {
    [self handleOnline];
  }
}

- (void)handleOffline
{}

- (void)handleOnline
{
  [self handleExtensionFiles];
}

#pragma mark - Extension Files Handling

- (void)temporaryFileManagerReady
{
  [self handleExtensionFiles];
}

- (void)handleExtensionFiles
{
  @synchronized(self)
  {
    if (![InfinitConnectionManager sharedInstance].was_logged_in ||
        ![InfinitTemporaryFileManager sharedInstance].ready)
    {
      return;
    }

    NSString* extension_files = [InfinitExtensionInfo sharedInstance].files_path;
    NSArray* contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:extension_files
                                                                            error:nil];
    if (contents.count == 0)
      return;

    InfinitTemporaryFileManager* manager = [InfinitTemporaryFileManager sharedInstance];
    _extension_uuid = [manager createManagedFiles];
    NSMutableArray* file_paths = [NSMutableArray array];
    for (NSString* file in contents)
      [file_paths addObject:[extension_files stringByAppendingPathComponent:file]];
    [manager addFiles:file_paths toManagedFiles:self.extension_uuid copy:NO];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(300 * NSEC_PER_MSEC)),
                   dispatch_get_main_queue(), ^
    {
      self.extension_controller.files =
        [[InfinitTemporaryFileManager sharedInstance] pathsForManagedFiles:self.extension_uuid];
      [self.overlay_controller showController:self.extension_controller];
    });
  }
}

- (void)extensionPopoverWantsSend:(InfinitExtensionPopoverController*)sender
{
  [self showSendViewForManagedFiles:self.extension_uuid];
}

#pragma mark - Wormhole Handling

- (void)pingReceived
{
  if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive)
  {
    [[InfinitWormhole sharedInstance] sendWormholeNotification:INFINIT_PONG_NOTIFICATION];
  }
}

- (void)extensionLocalFilesReceived
{
  NSString* folder = [InfinitExtensionInfo sharedInstance].internal_files_path;
  NSString* extension_files = [folder stringByAppendingPathComponent:@"files"];
  NSArray* files = [NSArray arrayWithContentsOfFile:extension_files];
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(500 * NSEC_PER_MSEC)),
                 dispatch_get_main_queue(), ^
  {
    [self showSendViewForFiles:files];
  });
  [[NSFileManager defaultManager] removeItemAtPath:extension_files error:nil];
}

#pragma mark - OverlayViewControllerProtocol

- (void)overlayViewController:(InfinitOverlayViewController*)sender
      userDidCancelController:(UIViewController*)controller
{
  if (controller == self.extension_controller)
  {
    [[InfinitTemporaryFileManager sharedInstance] deleteManagedFiles:self.extension_uuid];
  }
}

#pragma mark - Public

- (void)showSendGalleryView
{
  UISplitViewController* send_split_view =
    [self.storyboard instantiateViewControllerWithIdentifier:@"ipad_send_split_view_id"];
  [self presentViewController:send_split_view animated:YES completion:NULL];
}

- (void)showSendViewForFiles:(NSArray*)files
{
  if (files.count == 0)
    return;
  [self.recipient_controller resetView];
  self.recipient_controller.files = files;
  [self.overlay_controller showController:self.recipient_controller];
}

- (void)showSendViewForManagedFiles:(NSString*)uuid
{
  [self.recipient_controller resetView];
  self.recipient_controller.extension_files_uuid = uuid;
  [self.overlay_controller showController:self.recipient_controller];
}

- (void)showWelcomeScreen
{
  self.view.window.rootViewController =
    [self.storyboard instantiateViewControllerWithIdentifier:@"welcome_controller_id"];
}

- (void)showViewForFolder:(InfinitFolderModel*)folder
{
  InfinitFilesViewController_iPad* files_controller =
    (InfinitFilesViewController_iPad*)self.viewControllers[1];
  [files_controller showFolder:folder];
}

#pragma mark - Helpers

- (InfinitSendGalleryController*)gallery_controller
{
  if (_gallery_controller == nil)
  {
    _gallery_controller =
      [self.storyboard instantiateViewControllerWithIdentifier:@"send_gallery_controller_id"];
  }
  return _gallery_controller;
}

- (InfinitExtensionPopoverController*)extension_controller
{
  if (_extension_controller == nil)
  {
    _extension_controller =
      [self.storyboard instantiateViewControllerWithIdentifier:@"extension_popover_id"];
    self.extension_controller.delegate = self;
  }
  return _extension_controller;
}

- (InfinitOverlayViewController*)overlay_controller
{
  if (_overlay_controller == nil)
  {
    UINib* overlay_nib =
      [UINib nibWithNibName:NSStringFromClass(InfinitOverlayViewController.class)
                     bundle:nil];

    _overlay_controller = [overlay_nib instantiateWithOwner:self options:nil].firstObject;
    self.overlay_controller.delegate = self;
  }
  return _overlay_controller;
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
