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
#import "InfinitContactsViewController.h"
#import "InfinitFilesNavigationController.h"
#import "InfinitFilesViewController.h"
#import "InfinitHomeViewController.h"
#import "InfinitMetricsManager.h"
#import "InfinitOfflineOverlay.h"
#import "InfinitSendTabIcon.h"
#import "InfinitSendNavigationController.h"
#import "InfinitTabAnimator.h"

#import "JDStatusBarNotification.h"

#import <Gap/InfinitConnectionManager.h>
#import <Gap/InfinitPeerTransactionManager.h>

@import AssetsLibrary;

typedef NS_ENUM(NSUInteger, InfinitTabBarIndex)
{
  InfinitTabBarIndexHome = 0,
  InfinitTabBarIndexFiles,
  InfinitTabBarIndexSend,
  InfinitTabBarIndexContacts,
  InfinitTabBarIndexSettings,
};

@interface InfinitTabBarController () <UITabBarControllerDelegate>

@property (nonatomic, strong) InfinitTabAnimator* animator;
@property (nonatomic) NSUInteger last_index;
@property (nonatomic, strong) InfinitAccessGalleryView* permission_view;
@property (nonatomic, strong) UIView* selection_indicator;
@property (nonatomic, strong) InfinitSendTabIcon* send_tab_icon;
@property (nonatomic, strong) InfinitOfflineOverlay* offline_overlay;
@property (nonatomic) BOOL tab_bar_hidden;

@end

@implementation InfinitTabBarController
{
@private
  NSString* _status_bar_error_style_id;
  NSString* _status_bar_good_style_id;
  NSString* _status_bar_warning_style_id;

  BOOL _first_appear;
}

#pragma mark - Rotation

- (BOOL)shouldAutorotate
{
  return self.selectedViewController.shouldAutorotate;
}

- (NSUInteger)supportedInterfaceOrientations
{
  return self.selectedViewController.supportedInterfaceOrientations;
}

#pragma mark - Init

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
  _first_appear = NO;
  _animator = [[InfinitTabAnimator alloc] init];
  _status_bar_error_style_id = @"InfinitErrorStyle";
  _status_bar_good_style_id = @"InfinitGoodStyle";
  _status_bar_warning_style_id = @"InfinitWarningStyle";
  _tab_bar_hidden = NO;
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(newPeerTransaction:)
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
  [super viewDidLoad];

  self.delegate = self;
  self.tabBar.tintColor = [UIColor clearColor];

  [[UITabBar appearance] setBackgroundImage:[[UIImage alloc] init]];
  [[UITabBar appearance] setShadowImage:[[UIImage alloc] init]];

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
    [self.tabBar.items[index] setImage:[self imageForTabBarItem:index selected:NO]];
    [self.tabBar.items[index] setSelectedImage:[self imageForTabBarItem:index selected:YES]];
  }

  [JDStatusBarNotification addStyleNamed:_status_bar_error_style_id
                                 prepare:^JDStatusBarStyle* (JDStatusBarStyle* style)
   {
     style.barColor = [InfinitColor colorWithRed:255 green:63 blue:58];
     style.textColor = [UIColor whiteColor];
     style.font = [UIFont fontWithName:@"HelveticaNeue-Medium" size:11.0f];
     style.animationType = JDStatusBarAnimationTypeMove;
     return style;
   }];

  [JDStatusBarNotification addStyleNamed:_status_bar_good_style_id
                                 prepare:^JDStatusBarStyle* (JDStatusBarStyle* style)
   {
     style.barColor = [InfinitColor colorWithRed:43 green:190 blue:189];
     style.textColor = [UIColor whiteColor];
     style.font = [UIFont fontWithName:@"HelveticaNeue-Medium" size:11.0f];
     style.animationType = JDStatusBarAnimationTypeMove;
     return style;
   }];

  [JDStatusBarNotification addStyleNamed:_status_bar_warning_style_id
                                 prepare:^JDStatusBarStyle* (JDStatusBarStyle* style)
   {
     style.barColor = [InfinitColor colorWithRed:245 green:166 blue:35];
     style.textColor = [UIColor whiteColor];
     style.font = [UIFont fontWithName:@"HelveticaNeue-Medium" size:11.0f];
     style.animationType = JDStatusBarAnimationTypeMove;
     return style;
   }];

  [self updateHomeBadge];
}

- (void)viewWillAppear:(BOOL)animated
{
  [[UIApplication sharedApplication] setStatusBarHidden:NO];
  if (!_first_appear)
  {
    _first_appear = YES;
    if (![InfinitConnectionManager sharedInstance].connected)
      [self handleOffline];
    else
      [self handleOnline];
  }
  else
  {
    if (![InfinitConnectionManager sharedInstance].connected)
      [self handleOffline];
  }
  [super viewWillAppear:animated];
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
  [self.tabBar.items[0] setBadgeValue:badge];
}

- (UIImage*)imageForTabBarItem:(InfinitTabBarIndex)index
                      selected:(BOOL)selected
{
  [self.tabBar.items[index] setImageInsets:UIEdgeInsetsMake(5.0f, 0.0f, -5.0f, 0.0f)];
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
  [super setSelectedIndex:selectedIndex];
  [self selectorToPosition:selectedIndex];
}

- (void)showTabBarWithAnimation:(BOOL)animate
{
  if (!self.tab_bar_hidden)
    return;
  _tab_bar_hidden = NO;
  CGFloat d_h = self.tabBar.frame.size.height + 10.0f;
  CGRect final_bar_rect = CGRectOffset(self.tabBar.frame, 0.0f, - d_h);
  UIView* resize_view = self.selectedViewController.view;
  CGRect final_view_rect = [self growRect:resize_view.frame
                                  byWidth:0.0f
                                andHeight:-d_h];
  self.tabBar.hidden = NO;
  [UIView animateWithDuration:animate ? self.animator.linear_duration : 0.0f
                        delay:animate ? self.animator.linear_duration : 0.0f
                      options:UIViewAnimationOptionCurveEaseInOut
                   animations:^
   {
     self.tabBar.frame = final_bar_rect;
     resize_view.frame = final_view_rect;
   } completion:^(BOOL finished)
   {
     if (!finished)
     {
       self.tabBar.frame = final_bar_rect;
       resize_view.frame = final_view_rect;
     }
   }];
}

#pragma mark - General

- (void)lastSelectedIndex
{
  self.selectedIndex = _last_index;
}

- (void)setTabBarHidden:(BOOL)hidden
               animated:(BOOL)animate
{
  if (hidden)
  {
    [self hideTabBarWithAnimation:animate];
  }
  else
  {
    [self showTabBarWithAnimation:animate];
  }
}

- (void)showMainScreen
{
  [[UIApplication sharedApplication] setStatusBarHidden:NO];
  self.selectedIndex = InfinitTabBarIndexHome;
}

- (void)showFilesScreen
{
  [[UIApplication sharedApplication] setStatusBarHidden:NO];
  self.selectedIndex = InfinitTabBarIndexFiles;
}

- (void)showSendScreenWithContact:(InfinitContact*)contact
{
  [self hideTabBarWithAnimation:YES];
  _last_index = InfinitTabBarIndexContacts;
  if ([ALAssetsLibrary authorizationStatus] == ALAuthorizationStatusNotDetermined)
  {
    [self loadGalleryPermissionView];
    return;
  }
  else if ([ALAssetsLibrary authorizationStatus] == ALAuthorizationStatusDenied)
  {
    [self noGalleryAccessPopUp];
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
  UIStoryboard* board = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
  UIViewController* login_controller =
    [board instantiateViewControllerWithIdentifier:@"welcome_controller"];
  [self presentViewController:login_controller animated:YES completion:nil];
}

#pragma mark - Delegate Functions

- (BOOL)tabBarController:(UITabBarController*)tabBarController
shouldSelectViewController:(UIViewController*)viewController
{
  if ([self.viewControllers indexOfObject:viewController] == self.selectedIndex)
  {
    if ([viewController.title isEqualToString:@"HOME"])
    {
      UINavigationController* home_nav_controller = (UINavigationController*)viewController;
      [home_nav_controller.viewControllers.firstObject scrollToTop];
    }
    else if ([viewController.title isEqualToString:@"FILES"])
    {
      UINavigationController* files_nav_controller = (UINavigationController*)viewController;
      [files_nav_controller.viewControllers.firstObject tabIconTap];
    }
    else if ([viewController.title isEqualToString:@"CONTACTS"])
    {
      UINavigationController* contacts_nav_controller = (UINavigationController*)viewController;
      [contacts_nav_controller.viewControllers.firstObject tabIconTap];
    }
    return NO;
  }
  _last_index = self.selectedIndex;
  if ([viewController.title isEqualToString:@"SEND"])
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
    else if ([ALAssetsLibrary authorizationStatus] == ALAuthorizationStatusDenied)
    {
      [self noGalleryAccessPopUp];
      return NO;
    }
    else
    {
      [InfinitMetricsManager sendMetric:InfinitUIEventSendGalleryViewOpen
                                 method:InfinitUIMethodTabBar];
    }
    [self hideTabBarWithAnimation:YES];
  }
  [self selectorToPosition:[self.viewControllers indexOfObject:viewController]];
  return YES;
}

- (void)hideTabBarWithAnimation:(BOOL)animate
{
  if (self.tab_bar_hidden)
    return;
  _tab_bar_hidden = YES;
  CGFloat d_h = self.tabBar.frame.size.height + 10.0f;
  CGRect final_bar_rect = CGRectOffset(self.tabBar.frame, 0.0f, d_h);
  UIView* resize_view = self.selectedViewController.view;
  CGRect final_view_rect = [self growRect:resize_view.frame
                                  byWidth:0.0f
                                andHeight:d_h];
  [UIView animateWithDuration:animate ? self.animator.linear_duration : 0.0f
                        delay:animate ? self.animator.linear_duration : 0.0f
                      options:UIViewAnimationOptionCurveEaseInOut
                   animations:^
   {
     self.tabBar.frame = final_bar_rect;
     resize_view.frame = final_view_rect;
   } completion:^(BOOL finished)
   {
     if (!finished)
     {
       self.tabBar.frame = final_bar_rect;
       resize_view.frame = final_view_rect;
     }
     self.tabBar.hidden = YES;
   }];
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
}

- (id<UIViewControllerAnimatedTransitioning>)tabBarController:(UITabBarController*)tabBarController
           animationControllerForTransitionFromViewController:(UIViewController*)fromVC
                                             toViewController:(UIViewController*)toVC
{
  if ([toVC.title isEqualToString:@"SEND"] && self.permission_view == nil)
  {
    self.animator.reverse = NO;
    self.animator.animation = AnimateCircleCover;
    self.animator.animation_center =
      CGPointMake(self.view.frame.size.width / 2.0f, self.view.frame.size.height -
                  self.send_tab_icon.frame.size.height / 3.0f);
  }
  else if ([fromVC.title isEqualToString:@"SEND"])
  {
    InfinitSendNavigationController* send_nav_controller = (InfinitSendNavigationController*)fromVC;
    self.animator.reverse = YES;
    if ([send_nav_controller.topViewController.title isEqualToString:@"SEND_GALLERY"])
    {
      self.animator.animation = AnimateCircleCover;
      self.animator.animation_center =
        CGPointMake(self.view.frame.size.width / 2.0f, self.view.frame.size.height -
                    self.send_tab_icon.frame.size.height / 3.0f);
    }
    else if ([send_nav_controller.topViewController.title isEqualToString:@"SEND_RECIPIENTS"])
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
    NSLocalizedString(@"Tap \"OK\" to select your photos and videos.", nil);
  NSMutableAttributedString* res = [self.permission_view.message_label.attributedText mutableCopy];
  NSRange bold_range = [res.string rangeOfString:@"OK"];
  [res setAttributes:bold_attrs range:bold_range];
  self.permission_view.message_label.attributedText = res;
  ALAssetsLibrary* library = [[ALAssetsLibrary alloc] init];
  [library enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos
                         usingBlock:^(ALAssetsGroup* group, BOOL* stop)
   {
     *stop = YES;
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
     [self hideTabBarWithAnimation:NO];
     self.selectedIndex = InfinitTabBarIndexSend;
     [InfinitMetricsManager sendMetric:InfinitUIEventAccessGallery
                                method:InfinitUIMethodYes];
     [InfinitMetricsManager sendMetric:InfinitUIEventSendGalleryViewOpen
                                method:InfinitUIMethodTabBar];
   } failureBlock:^(NSError* error)
   {
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
{
  InfinitConnectionManager* manager = [InfinitConnectionManager sharedInstance];
  if (manager.network_status == InfinitNetworkStatusNotReachable)
  {
    [JDStatusBarNotification showWithStatus:@"You're currently offline..."
                                  styleName:_status_bar_warning_style_id];
  }
  else
  {
    [JDStatusBarNotification showWithStatus:@"Reconnecting..."
                               dismissAfter:2.0f
                                  styleName:_status_bar_warning_style_id];
    [JDStatusBarNotification showActivityIndicator:YES
                                    indicatorStyle:UIActivityIndicatorViewStyleWhite];
  }
}

- (void)handleOnline
{
  [JDStatusBarNotification showWithStatus:@"Connected!"
                             dismissAfter:2.0f
                                styleName:_status_bar_good_style_id];
  [self.offline_overlay removeFromSuperview];
}

#pragma mark - Peer Transaction Notifications

- (void)newPeerTransaction:(NSNotification*)notification
{
  [self performSelectorOnMainThread:@selector(updateHomeBadge) withObject:nil waitUntilDone:NO];
}

- (void)peerTransactionUpdated:(NSNotification*)notification
{
  [self performSelectorOnMainThread:@selector(updateHomeBadge) withObject:nil waitUntilDone:NO];
}

#pragma mark - Connection Handling

- (void)connectionStatusChanged:(NSNotification*)notification
{
  InfinitConnectionStatus* connection_status = notification.object;
  if (!connection_status.status && !connection_status.still_trying)
  {
    [self performSelectorOnMainThread:@selector(showWelcomeScreen) withObject:nil waitUntilDone:NO];
  }
  else if (!connection_status.status)
  {
    [self performSelectorOnMainThread:@selector(handleOffline)
                           withObject:nil
                        waitUntilDone:NO];
  }
  else if (connection_status.status)
  {
    [self performSelectorOnMainThread:@selector(handleOnline)
                           withObject:nil
                        waitUntilDone:NO];
  }
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

@end
