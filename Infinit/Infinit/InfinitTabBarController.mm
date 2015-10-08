//
//  InfTabBarController.m
//  Infinit
//
//  Created by Michael Dee on 6/27/14.
//  Copyright (c) 2014 Michael Dee. All rights reserved.
//

#import "InfinitTabBarController.h"

#import "InfinitAccessGalleryView.h"
#import "InfinitColor.h"
#import "InfinitContactManager.h"
#import "InfinitContactsViewController.h"
#import "InfinitExtensionInfo.h"
#import "InfinitExtensionPopoverController.h"
#import "InfinitFilesNavigationController.h"
#import "InfinitFilesViewController.h"
#import "InfinitHomeViewController.h"
#import "InfinitHostDevice.h"
#import "InfinitMetricsManager.h"
#import "InfinitOverlayViewController.h"
#import "InfinitOfflineOverlay.h"
#import "InfinitSendTabIcon.h"
#import "InfinitSendNavigationController.h"
#import "InfinitTabAnimator.h"
#import "InfinitWormhole.h"

#import "JDStatusBarNotification.h"

#import <Gap/InfinitConnectionManager.h>
#import <Gap/InfinitPeerTransactionManager.h>
#import <Gap/InfinitStateManager.h>
#import <Gap/InfinitTemporaryFileManager.h>

#import <AddressBook/AddressBook.h>
#import <AssetsLibrary/AssetsLibrary.h>

#undef check
#import <elle/log.hh>

ELLE_LOG_COMPONENT("iOS.TabBarController");

typedef NS_ENUM(NSUInteger, InfinitTabBarIndex)
{
  InfinitTabBarIndexHome = 0,
  InfinitTabBarIndexFiles,
  InfinitTabBarIndexSend,
  InfinitTabBarIndexContacts,
  InfinitTabBarIndexSettings,
};

@interface InfinitTabBarController () <InfinitExtensionPopoverProtocol,
                                       InfinitOverlayViewControllerProtocol,
                                       UINavigationControllerDelegate,
                                       UITabBarControllerDelegate>

@property (nonatomic, strong) InfinitTabAnimator* animator;
@property (atomic, readwrite) BOOL first_appear;
@property (nonatomic) NSUInteger last_index;
@property (nonatomic, strong) InfinitAccessGalleryView* permission_view;
@property (nonatomic, strong) UIView* selection_indicator;
@property (nonatomic, strong) InfinitSendTabIcon* send_tab_icon;
@property (nonatomic, strong) InfinitOfflineOverlay* offline_overlay;
@property (nonatomic, strong) InfinitOverlayViewController* overlay_controller;
@property (nonatomic) BOOL tab_bar_hidden;

@property (nonatomic, strong) InfinitExtensionPopoverController* extension_popover;
@property (nonatomic, readonly) InfinitManagedFiles* managed_files;

@property (nonatomic, readonly) NSString* status_bar_error_style_id;
@property (nonatomic, readonly) NSString* status_bar_good_style_id;
@property (nonatomic, readonly) NSString* status_bar_warning_style_id;

@end

static InfinitTabBarController* _current_instance = nil;

@implementation InfinitTabBarController

#pragma mark - Rotation

- (BOOL)shouldAutorotate
{
  return self.selectedViewController.shouldAutorotate;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
  return self.selectedViewController.supportedInterfaceOrientations;
}

#pragma mark - Application Status Changes

- (void)applicationBecameActive
{
  [self handleExtensionFiles];
}

#pragma mark - Init

- (void)dealloc
{
  [[InfinitWormhole sharedInstance] unregisterForWormholeNotifications:self];
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
  self.first_appear = NO;
  _animator = [[InfinitTabAnimator alloc] init];
  _status_bar_error_style_id = @"InfinitErrorStyle";
  _status_bar_good_style_id = @"InfinitGoodStyle";
  _status_bar_warning_style_id = @"InfinitWarningStyle";
  _tab_bar_hidden = NO;
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(peerTransactionUpdated:)
                                               name:INFINIT_NEW_PEER_TRANSACTION_NOTIFICATION
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(peerTransactionUpdated:)
                                               name:INFINIT_PEER_TRANSACTION_STATUS_NOTIFICATION
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(connectionStatusChanged:)
                                               name:INFINIT_CONNECTION_STATUS_CHANGE
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(applicationBecameActive)
                                               name:UIApplicationDidBecomeActiveNotification
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(temporaryFileManagerReady)
                                               name:INFINIT_TEMPORARY_FILE_MANAGER_READY
                                             object:nil];
  if ([InfinitHostDevice iOSVersion] >= 8.0)
  {
    InfinitWormhole* wormhole = [InfinitWormhole sharedInstance];
    [wormhole registerForWormholeNotification:INFINIT_PING_NOTIFICATION
                                     observer:self
                                     selector:@selector(pingReceived)];
    [wormhole registerForWormholeNotification:INFINIT_EXTENSION_FILES_NOTIFICATION
                                     observer:self 
                                     selector:@selector(extensionLocalFilesReceived)];
  }
  [super viewDidLoad];

  _current_instance = self;

  UIViewController* home_controller =
    [self.storyboard instantiateViewControllerWithIdentifier:@"home_navigation_controller_id"];
  UIViewController* files_controller =
    [self.storyboard instantiateViewControllerWithIdentifier:@"files_navigation_controller_id"];
  UIViewController* send_controller =
    [self.storyboard instantiateViewControllerWithIdentifier:@"send_navigation_controller_id"];
  UIViewController* contacts_controller =
    [self.storyboard instantiateViewControllerWithIdentifier:@"contacts_navigation_controller_id"];
  UIViewController* settings_controller =
    [self.storyboard instantiateViewControllerWithIdentifier:@"settings_navigation_controller_id"];
  self.viewControllers = @[home_controller,
                           files_controller,
                           send_controller,
                           contacts_controller,
                           settings_controller];

  [JDStatusBarNotification addStyleNamed:self.status_bar_error_style_id
                                 prepare:^JDStatusBarStyle* (JDStatusBarStyle* style)
   {
     style.barColor = [InfinitColor colorWithRed:255 green:63 blue:58];
     style.textColor = [UIColor whiteColor];
     style.font = [UIFont fontWithName:@"HelveticaNeue-Medium" size:11.0f];
     style.animationType = JDStatusBarAnimationTypeMove;
     return style;
   }];

  [JDStatusBarNotification addStyleNamed:self.status_bar_good_style_id
                                 prepare:^JDStatusBarStyle* (JDStatusBarStyle* style)
   {
     style.barColor = [InfinitColor colorWithRed:43 green:190 blue:189];
     style.textColor = [UIColor whiteColor];
     style.font = [UIFont fontWithName:@"HelveticaNeue-Medium" size:11.0f];
     style.animationType = JDStatusBarAnimationTypeMove;
     return style;
   }];

  [JDStatusBarNotification addStyleNamed:self.status_bar_warning_style_id
                                 prepare:^JDStatusBarStyle* (JDStatusBarStyle* style)
   {
     style.barColor = [InfinitColor colorWithRed:245 green:166 blue:35];
     style.textColor = [UIColor whiteColor];
     style.font = [UIFont fontWithName:@"HelveticaNeue-Medium" size:11.0f];
     style.animationType = JDStatusBarAnimationTypeMove;
     return style;
   }];
}

- (void)viewWillAppear:(BOOL)animated
{
  if ([InfinitStateManager sharedInstance].logged_in && [self addressBookAccessible])
    [[InfinitContactManager sharedInstance] gotAddressBookAccess];
  [super viewWillAppear:animated];
  [[UIApplication sharedApplication] setStatusBarHidden:NO];
  if (!self.first_appear)
  {
    self.first_appear = YES;
    if (![InfinitConnectionManager sharedInstance].connected)
      [self handleOffline];
    else
      [self handleOnlineInitial:YES];
    self.delegate = self;
    self.tabBar.tintColor = [UIColor clearColor];

    [[UITabBar appearance] setBackgroundImage:[[UIImage alloc] init]];
    self.tabBar.shadowImage = [[UIImage alloc] init];

    UIView* shadow_line =
      [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.view.frame.size.width, 1.0f)];
    shadow_line.backgroundColor = [InfinitColor colorWithGray:216.0f];
    [self.tabBar addSubview:shadow_line];

    _selection_indicator =
    [[UIView alloc] initWithFrame:CGRectMake(0.0f,
                                             0.0f,
                                             self.view.frame.size.width / self.viewControllers.count,
                                             1.0f)];
    self.selection_indicator.backgroundColor =
    [InfinitColor colorFromPalette:InfinitPaletteColorBurntSienna];
    [self.tabBar addSubview:self.selection_indicator];

    UIImage* send_icon_bg = [UIImage imageNamed:@"icon-tab-send-bg"];
    _send_tab_icon = [[InfinitSendTabIcon alloc] initWithFrame:CGRectMake(0.0f,
                                                                          0.0f,
                                                                          send_icon_bg.size.width,
                                                                          send_icon_bg.size.height)];
    [self.tabBar addSubview:self.send_tab_icon];
    CGFloat delta = (self.tabBar.bounds.size.height - send_icon_bg.size.height) / 2.0f;
    self.send_tab_icon.center = CGPointMake(self.tabBar.bounds.size.width / 2.0f,
                                            (self.tabBar.bounds.size.height / 2.0f) + delta);
    for (NSUInteger index = 0; index < self.tabBar.items.count; index++)
    {
      if (index == InfinitTabBarIndexSend)
        continue;
      [self.tabBar.items[index] setImageInsets:UIEdgeInsetsMake(5.0f, 0.0f, -5.0f, 0.0f)];
      [self.tabBar.items[index] setImage:[self imageForTabBarItem:index selected:NO]];
      [self.tabBar.items[index] setSelectedImage:[self imageForTabBarItem:index selected:YES]];
    }
  }
  else
  {
    if (![InfinitConnectionManager sharedInstance].connected)
      [self handleOffline];
  }
  [self updateHomeBadge];
}

- (void)viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];
  [self handleExtensionFiles];
}

- (void)viewWillDisappear:(BOOL)animated
{
  [super viewWillDisappear:animated];
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

- (UIImage*)imageForTabBarItem:(NSUInteger)index_
                      selected:(BOOL)selected
{
  InfinitTabBarIndex index = static_cast<InfinitTabBarIndex>(index_);
  NSString* image_name = nil;
  switch (index)
  {
    case InfinitTabBarIndexHome:
      image_name = @"icon-tab-home";
      break;
    case InfinitTabBarIndexFiles:
      image_name = @"icon-tab-files";
      break;
    case InfinitTabBarIndexSend:
      return nil;
    case InfinitTabBarIndexContacts:
      image_name = @"icon-tab-contacts";
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

- (void)setSelectedIndex:(NSUInteger)selectedIndex
{
  if (selectedIndex == self.selectedIndex)
    return;
  if (selectedIndex == InfinitTabBarIndexContacts)
  {
    UIViewController* view_controller = self.viewControllers[InfinitTabBarIndexContacts];
    if ([view_controller isKindOfClass:InfinitContactsViewController.class])
      ((InfinitContactsViewController*)view_controller).invitation_mode = NO;
  }
  [super setSelectedIndex:selectedIndex];
  [self selectorToPosition:selectedIndex];
}

#pragma mark - General

+ (InfinitTabBarController*)currentTabBarController
{
  return _current_instance;
}

- (void)lastSelectedIndex
{
  self.selectedIndex = _last_index;
}

- (void)setTabBarHidden:(BOOL)hidden
               animated:(BOOL)animate
{
  [self setTabBarHidden:hidden animated:animate withDelay:0.0f];
}

- (void)setTabBarHidden:(BOOL)hidden
               animated:(BOOL)animate
              withDelay:(NSTimeInterval)delay
{
  if (self.tabBar.hidden == hidden)
    return;

  CGSize screen_size = [[UIScreen mainScreen] bounds].size;
  BOOL landscape = NO;
  switch ([UIApplication sharedApplication].statusBarOrientation)
  {
    case UIInterfaceOrientationLandscapeLeft:
    case UIInterfaceOrientationLandscapeRight:
      landscape = YES;
      break;

    default:
      landscape = NO;
      break;
  }
  float height =  landscape ? screen_size.width : screen_size.height;

  if (!hidden)
  {
    height -= CGRectGetHeight(self.tabBar.frame);
    self.tabBar.hidden = NO;
  }
  else
  {
    height += CGRectGetHeight(self.send_tab_icon.frame) - CGRectGetHeight(self.tabBar.frame);
  }

  UIView* view = self.selectedViewController.view;

  [UIView animateWithDuration:(animate ? self.animator.linear_duration : 0.0f)
                        delay:delay
                      options:0
                   animations:^
  {
    CGRect frame = self.tabBar.frame;
    frame.origin.y = height;
    self.tabBar.frame = frame;
    frame = view.frame;
    frame.size.height += (hidden ? 1.0f : -1.0f) * CGRectGetHeight(self.tabBar.frame);
    view.frame = frame;
  } completion:^(BOOL finished)
  {
    self.tabBar.hidden = hidden;
  }];
}

- (void)showMainScreen:(id)sender
{
  [[UIApplication sharedApplication] setStatusBarHidden:NO];
  if (self.selectedIndex == InfinitTabBarIndexHome)
    [((UIViewController*)sender).navigationController popToRootViewControllerAnimated:YES];
  else
    self.selectedIndex = InfinitTabBarIndexHome;
}

- (void)showContactsScreen
{
  [[UIApplication sharedApplication] setStatusBarHidden:NO];
  self.selectedIndex = InfinitTabBarIndexContacts;
}

- (void)showFilesScreen
{
  [[UIApplication sharedApplication] setStatusBarHidden:NO];
  self.selectedIndex = InfinitTabBarIndexFiles;
}

- (void)showSendScreenWithContact:(InfinitContact*)contact
{
  if ([ALAssetsLibrary authorizationStatus] == ALAuthorizationStatusRestricted ||
      [ALAssetsLibrary authorizationStatus] == ALAuthorizationStatusDenied)
  {
    [self noGalleryAccessPopUp];
    return;
  }
   _last_index = InfinitTabBarIndexContacts;
  [self setTabBarHidden:YES animated:YES withDelay:self.animator.linear_duration];
  if ([ALAssetsLibrary authorizationStatus] == ALAuthorizationStatusNotDetermined)
  {
    [self loadGalleryPermissionView];
    return;
  }
  InfinitSendNavigationController* nav_controller = self.viewControllers[InfinitTabBarIndexSend];
  nav_controller.recipient = contact;
  self.selectedIndex = InfinitTabBarIndexSend;
  [InfinitMetricsManager sendMetric:InfinitUIEventSendGalleryViewOpen
                             method:InfinitUIMethodContact];
}

- (void)showWelcomeScreen
{
  self.view.window.rootViewController =
    [self.storyboard instantiateViewControllerWithIdentifier:@"welcome_nav_controller_id"];
}

- (void)showTransactionPreparingNotification
{
  [JDStatusBarNotification showWithStatus:NSLocalizedString(@"Preparing your transfer...", nil)
                             dismissAfter:3.0f
                                styleName:_status_bar_good_style_id];
  [JDStatusBarNotification showActivityIndicator:YES
                                  indicatorStyle:UIActivityIndicatorViewStyleWhite];
}

- (void)showCopyToGalleryNotification
{
  [JDStatusBarNotification showWithStatus:NSLocalizedString(@"Saving to gallery...", nil)
                             dismissAfter:3.0f
                                styleName:_status_bar_good_style_id];
  [JDStatusBarNotification showActivityIndicator:YES
                                  indicatorStyle:UIActivityIndicatorViewStyleWhite];
}

#pragma mark - Delegate Functions

- (BOOL)tabBarController:(UITabBarController*)tabBarController
shouldSelectViewController:(UIViewController*)viewController
{
  if ([self.viewControllers indexOfObject:viewController] == self.selectedIndex)
  {
    if ([viewController.restorationIdentifier isEqualToString:@"home_navigation_controller_id"])
    {
      UINavigationController* home_nav_controller = (UINavigationController*)viewController;
      [home_nav_controller.viewControllers.firstObject scrollToTop];
    }
    else if ([viewController.restorationIdentifier isEqualToString:@"files_navigation_controller_id"])
    {
      UINavigationController* files_nav_controller = (UINavigationController*)viewController;
      [files_nav_controller.viewControllers.firstObject tabIconTap];
    }
    else if ([viewController.restorationIdentifier isEqualToString:@"contacts_navigation_controller_id"])
    {
      UINavigationController* contacts_nav_controller = (UINavigationController*)viewController;
      [contacts_nav_controller.viewControllers.firstObject tabIconTap];
    }
    return NO;
  }
  _last_index = self.selectedIndex;
  if ([viewController.restorationIdentifier isEqualToString:@"send_navigation_controller_id"])
  {
    if ([InfinitConnectionManager sharedInstance].was_logged_in)
    {
      if ([JDStatusBarNotification isVisible])
        [JDStatusBarNotification dismiss];
    }
    if ([ALAssetsLibrary authorizationStatus] == ALAuthorizationStatusNotDetermined)
    {
      [self loadGalleryPermissionView];
      return NO;
    }
    else if ([ALAssetsLibrary authorizationStatus] == ALAuthorizationStatusRestricted ||
             [ALAssetsLibrary authorizationStatus] == ALAuthorizationStatusDenied)
    {
      [self noGalleryAccessPopUp];
      return NO;
    }
    else
    {
      [InfinitMetricsManager sendMetric:InfinitUIEventSendGalleryViewOpen
                                 method:InfinitUIMethodTabBar];
    }
    [self setTabBarHidden:YES animated:YES withDelay:self.animator.linear_duration];
  }
  [self selectorToPosition:[self.viewControllers indexOfObject:viewController]];
  return YES;
}

- (void)noGalleryAccessPopUp
{
  NSString* message = NSLocalizedString(@"Infinit requires access to your camera roll", nil);
  UIAlertView* alert = [[UIAlertView alloc] initWithTitle:nil
                                                  message:message
                                                 delegate:nil
                                        cancelButtonTitle:@"OK"
                                        otherButtonTitles:nil];
  [alert show];
  NSString* status = nil;
  switch ([ALAssetsLibrary authorizationStatus])
  {
    case ALAuthorizationStatusNotDetermined:
      status = @"not determined";
      break;
    case ALAuthorizationStatusDenied:
      status = @"denied";
      break;
    case ALAuthorizationStatusRestricted:
      status = @"restricted";
      break;

    default:
      status = @"unknown";
      break;
  }
  ELLE_WARN("%s: unable to access gallery, authorization status: %s",
            self.description.UTF8String, status.UTF8String);
}

- (id<UIViewControllerAnimatedTransitioning>)tabBarController:(UITabBarController*)tabBarController
           animationControllerForTransitionFromViewController:(UIViewController*)fromVC
                                             toViewController:(UIViewController*)toVC
{
  if ([toVC.restorationIdentifier isEqualToString:@"send_navigation_controller_id"]
      && self.permission_view == nil)
  {
    self.animator.reverse = NO;
    self.animator.animation = AnimateCircleCover;
    self.animator.animation_center =
      CGPointMake(self.view.frame.size.width / 2.0f,
                  self.view.frame.size.height - self.send_tab_icon.frame.size.height / 3.0f);
  }
  else if ([fromVC.restorationIdentifier isEqualToString:@"send_navigation_controller_id"])
  {
    InfinitSendNavigationController* send_nav_controller = (InfinitSendNavigationController*)fromVC;
    self.animator.reverse = YES;
    if ([send_nav_controller.topViewController.restorationIdentifier isEqualToString:@"send_gallery_controller_id"])
    {
      self.animator.animation = AnimateCircleCover;
      self.animator.animation_center =
        CGPointMake(self.view.frame.size.width / 2.0f, self.view.frame.size.height -
                    self.send_tab_icon.frame.size.height / 3.0f);
    }
    else
    {
      self.animator.animation = AnimateDownUp;
    }
  }
  else
  {
    return nil;
  }
  return self.animator;
}

- (void)loadGalleryPermissionView
{
  [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
  UINib* permission_nib = [UINib nibWithNibName:@"InfinitAccessGalleryView" bundle:nil];
  self.permission_view = [[permission_nib instantiateWithOwner:self options:nil] firstObject];
  self.permission_view.frame = CGRectMake(0.0f, 0.0f,
                                          self.view.frame.size.width, self.view.frame.size.height);
  CGPoint center = CGPointMake(self.view.frame.size.width / 2.0f, self.view.frame.size.height -
                               self.send_tab_icon.frame.size.height / 3.0f);
  CGFloat radius = hypotf(self.view.frame.size.width, self.view.frame.size.height);
  CGRect start_rect = CGRectMake(center.x, center.y, 0.0f, 0.0f);
  CGRect final_rect = CGRectMake(center.x - radius, center.y - radius,
                                 2.0f * radius, 2.0f * radius);
  self.permission_view.layer.mask = [self animatedMaskLayerFrom:start_rect
                                                             to:final_rect
                                                   withDuration:0.5f
                                             andCompletionBlock:nil];
  [self.permission_view.access_button addTarget:self
                                         action:@selector(accessGallery:)
                               forControlEvents:UIControlEventTouchUpInside];
  [self.view addSubview:self.permission_view];
  [self.view bringSubviewToFront:self.permission_view];
}

- (void)accessGallery:(id)sender
{
  self.permission_view.access_button.enabled = NO;
  self.permission_view.access_button.hidden = YES;
  self.permission_view.image_view.hidden = YES;
  NSDictionary* bold_attrs = @{NSFontAttributeName: [UIFont fontWithName:@"HelveticaNeue-Bold"
                                                                    size:20.0f],
                               NSForegroundColorAttributeName: [UIColor whiteColor]};
  self.permission_view.message_label.text =
    NSLocalizedString(@"Tap 'OK' to select your photos and videos.", nil);
  NSMutableAttributedString* res = [self.permission_view.message_label.attributedText mutableCopy];
  NSRange bold_range = [res.string rangeOfString:@"OK"];
  [res setAttributes:bold_attrs range:bold_range];
  self.permission_view.message_label.attributedText = res;
  ALAssetsLibrary* library = [[ALAssetsLibrary alloc] init];
  [library enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos
                         usingBlock:^(ALAssetsGroup* group, BOOL* stop)
   {
     *stop = YES;
     static dispatch_once_t _gallery_access = 0;
     dispatch_once(&_gallery_access, ^
     {
       CGPoint center = CGPointMake(self.view.frame.size.width / 2.0f, self.view.frame.size.height -
                                    self.send_tab_icon.frame.size.height / 3.0f);
       CGFloat radius = hypotf(self.view.frame.size.width, self.view.frame.size.height);
       CGRect start_rect = CGRectMake(center.x - radius, center.y - radius,
                                      2.0f * radius, 2.0f * radius);
       CGRect final_rect = CGRectMake(center.x, center.y, 0.0f, 0.0f);
       self.permission_view.layer.mask = [self animatedMaskLayerFrom:start_rect
                                                                  to:final_rect
                                                        withDuration:0.5f
                                                  andCompletionBlock:^
        {
          [self.permission_view performSelector:@selector(removeFromSuperview)
                                     withObject:nil
                                     afterDelay:0.51f];
          self.permission_view = nil;
        }];
       [self setTabBarHidden:YES animated:NO];
       self.selectedIndex = InfinitTabBarIndexSend;
       [InfinitMetricsManager sendMetric:InfinitUIEventAccessGallery
                                  method:InfinitUIMethodYes];
       [InfinitMetricsManager sendMetric:InfinitUIEventSendGalleryViewOpen
                                  method:InfinitUIMethodTabBar];
     });
   } failureBlock:^(NSError* error)
   {
     if (self.selectedIndex == InfinitTabBarIndexContacts)
     {
       [[UIApplication sharedApplication] setStatusBarHidden:NO
                                               withAnimation:UIStatusBarAnimationFade];
       [self setTabBarHidden:NO animated:NO];
     }
     [self noGalleryAccessPopUp];
     [InfinitMetricsManager sendMetric:InfinitUIEventAccessGallery
                                method:InfinitUIMethodNo];
     [self.permission_view removeFromSuperview];
     if (error.code == ALAssetsLibraryAccessUserDeniedError)
     {
       NSLog(@"user denied access, code: %li", (long)error.code);
     }
     else
     {
       NSLog(@"Other error code: %li", (long)error.code);
     }
   }];
}

- (void)selectorToPosition:(NSInteger)position
{
  if (position == InfinitTabBarIndexSend)
  {
    self.selection_indicator.frame = CGRectMake(0.0f, 0.0f, 0.0f, 0.0f);
    return;
  }
  NSUInteger count = self.viewControllers.count;
  self.selection_indicator.frame = CGRectMake(self.view.frame.size.width / count * position, 0.0f,
                                              self.view.frame.size.width / count, 1.0f);
}

#pragma mark - Offline Warning

- (void)handleOffline
{}

- (void)handleOnline
{
  [self handleOnlineInitial:NO];
}

- (void)handleOnlineInitial:(BOOL)initial
{
  [self.offline_overlay removeFromSuperview];
  if (!initial)
    [self handleExtensionFiles];
}


#pragma mark - Peer Transaction Notifications

- (void)peerTransactionUpdated:(NSNotification*)notification
{
  [self updateHomeBadge];
}

#pragma mark - Connection Handling

- (void)connectionStatusChanged:(NSNotification*)notification
{
  InfinitConnectionStatus* connection_status = notification.object;
  if (!connection_status.status && connection_status.still_trying)
  {
    [self handleOffline];
  }
  else if (connection_status.status)
  {
    [self handleOnline];
  }
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
    _managed_files = [manager createManagedFiles];
    NSMutableArray* file_paths = [NSMutableArray array];
    for (NSString* file in contents)
      [file_paths addObject:[extension_files stringByAppendingPathComponent:file]];
    [manager addFilesByMove:file_paths toManagedFiles:self.managed_files];
    [self showMainScreen:self.viewControllers[self.selectedIndex]];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(300 * NSEC_PER_MSEC)),
                   dispatch_get_main_queue(), ^
    {
      self.extension_popover.files = self.managed_files.managed_paths.array;
      [self.overlay_controller showController:self.extension_popover];
    });
  }
}

#pragma mark - Extension Popover Delegate

- (void)extensionPopoverWantsSend:(InfinitExtensionPopoverController*)sender
{
  [self.overlay_controller hideController];
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(400 * NSEC_PER_MSEC)),
                 dispatch_get_main_queue(), ^
  {
    InfinitHomeViewController* home_controller =
      (InfinitHomeViewController*)[self.viewControllers[InfinitTabBarIndexHome] topViewController];
    [home_controller showRecipientsForManagedFiles:self.managed_files];
    _managed_files = nil;
  });
}

#pragma mark - Overlay Delegate

- (void)overlayViewController:(InfinitOverlayViewController*)sender
      userDidCancelController:(UIViewController*)controller
{
  if (controller == self.extension_popover)
  {
    [[InfinitTemporaryFileManager sharedInstance] deleteManagedFiles:self.managed_files];
    _managed_files = nil;
    [InfinitMetricsManager sendMetric:InfinitUIEventExtensionCancel method:InfinitUIMethodNone];
  }
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
  [self showMainScreen:self.viewControllers[self.selectedIndex]];
  InfinitHomeViewController* home_controller =
    (InfinitHomeViewController*)[self.viewControllers[InfinitTabBarIndexHome] topViewController];
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(500 * NSEC_PER_MSEC)),
                 dispatch_get_main_queue(), ^
  {
    [home_controller showRecipientsForLocalFiles:files];
  });
  [[NSFileManager defaultManager] removeItemAtPath:extension_files error:nil];
}

#pragma mark - Helpers

- (CALayer*)animatedMaskLayerFrom:(CGRect)start_rect
                               to:(CGRect)final_rect
                     withDuration:(CGFloat)duration
               andCompletionBlock:(void (^)(void))block
{
  [CATransaction begin];
  CABasicAnimation* anim = [CABasicAnimation animationWithKeyPath:@"path"];
  anim.duration = 0.5f;
  anim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
  anim.fromValue = (__bridge id)([UIBezierPath bezierPathWithOvalInRect:start_rect].CGPath);
  anim.toValue = (__bridge id)([UIBezierPath bezierPathWithOvalInRect:final_rect].CGPath);
  CAShapeLayer* res = [CAShapeLayer layer];
  res.path = [UIBezierPath bezierPathWithOvalInRect:final_rect].CGPath;
  res.backgroundColor = [UIColor blackColor].CGColor;
  [CATransaction setCompletionBlock:block];
  [res addAnimation:anim forKey:anim.keyPath];
  [CATransaction commit];
  return res;
}

- (CGRect)growRect:(CGRect)old_rect
           byWidth:(CGFloat)width
         andHeight:(CGFloat)height
{
  return CGRectMake(old_rect.origin.x, old_rect.origin.y,
                    old_rect.size.width + width, old_rect.size.height + height);
}

- (InfinitOverlayViewController*)overlay_controller
{
  if (_overlay_controller == nil)
  {
    UINib* overlay_nib = [UINib nibWithNibName:NSStringFromClass(InfinitOverlayViewController.class)
                                        bundle:nil];

    _overlay_controller = [overlay_nib instantiateWithOwner:self options:nil].firstObject;
    self.overlay_controller.delegate = self;
  }
  return _overlay_controller;
}

- (InfinitExtensionPopoverController*)extension_popover
{
  if (_extension_popover == nil)
  {
    _extension_popover =
      [self.storyboard instantiateViewControllerWithIdentifier:@"extension_popover_id"];
    self.extension_popover.delegate = self;
  }
  return _extension_popover;
}

- (BOOL)addressBookAccessible
{
  return (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized);
}

@end
