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
#import "InfinitHomeViewController.h"
#import "InfinitSendTabIcon.h"
#import "InfinitSendNavigationController.h"
#import "InfinitTabAnimator.h"

#import <Gap/InfinitPeerTransactionManager.h>

@import AssetsLibrary;

typedef NS_ENUM(NSUInteger, InfinitTabBarIndex)
{
  TabBarIndexHome = 0,
  TabBarIndexFiles,
  TabBarIndexSend,
  TabBarIndexContacts,
  TabBarIndexSettings,
};

@interface InfinitTabBarController ()

@property (nonatomic) NSUInteger last_index;
@property (nonatomic, strong) InfinitAccessGalleryView* permission_view;
@property (nonatomic, strong) UIView* selection_indicator;
@property (nonatomic, strong) InfinitSendTabIcon* send_tab_icon;
@property (nonatomic, strong) InfinitTabAnimator* animator;
@property (nonatomic) BOOL tab_bar_hidden;

@end

@implementation InfinitTabBarController

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

- (id)initWithCoder:(NSCoder*)aDecoder
{
  if (self = [super initWithCoder:aDecoder])
  {
    _animator = [[InfinitTabAnimator alloc] init];
    _tab_bar_hidden = NO;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(newPeerTransaction:) 
                                                 name:INFINIT_NEW_PEER_TRANSACTION_NOTIFICATION
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(peerTransactionUpdated:)
                                                 name:INFINIT_PEER_TRANSACTION_STATUS_NOTIFICATION
                                               object:nil];
  }
  return self;
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
  [super viewDidLoad];

  self.delegate = self;
  self.tabBar.tintColor = [InfinitColor colorFromPalette:ColorShamRock];

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
  self.selection_indicator.backgroundColor = [InfinitColor colorFromPalette:ColorBurntSienna];
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
    [self.tabBar.items[index] setSelectedImage:[self imageForTabBarItem:index selected:NO]];
    [self.tabBar.items[index] setSelectedImage:[self imageForTabBarItem:index selected:YES]];
  }
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
    badge = [NSString stringWithFormat:@"%lu", count];
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
    case TabBarIndexHome:
      image_name = @"icon-tab-home";
      break;
    case TabBarIndexFiles:
      image_name = @"icon-tab-files";
      break;
    case TabBarIndexSend:
      return nil;
    case TabBarIndexContacts:
      image_name = @"icon-tab-contacts";
      break;
    case TabBarIndexSettings:
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
  CGRect final_bar_rect = CGRectOffset(self.tabBar.frame, 0.0f, - self.tabBar.frame.size.height);
  CGRect final_view_rect = [self growRect:self.view.frame
                                  byWidth:0.0f
                                andHeight:-self.tabBar.frame.size.height];
  if (animate)
  {
    [UIView animateWithDuration:self.animator.linear_duration
                          delay:self.animator.circular_duration / 2.0f
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^
     {
       self.tabBar.frame = final_bar_rect;
       self.view.frame = final_view_rect;
       [self.view layoutIfNeeded];
     } completion:^(BOOL finished)
     {
       if (!finished)
       {
         self.tabBar.frame = final_bar_rect;
         self.view.frame = final_view_rect;
       }
     }];
  }
  else
  {
    self.tabBar.frame = final_bar_rect;
    self.view.frame = final_view_rect;
  }
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
  self.selectedIndex = TabBarIndexHome;
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
    return NO;
  }
  _last_index = self.selectedIndex;
  if ([viewController.title isEqualToString:@"SEND"])
  {
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
    [self hideTabBarWithAnimation:YES];
  }
  NSUInteger index = [self.viewControllers indexOfObject:viewController];
  [self selectorToPosition:index];
  return YES;
}

- (void)hideTabBarWithAnimation:(BOOL)animate
{
  if (self.tab_bar_hidden)
    return;
  _tab_bar_hidden = YES;
  CGRect final_bar_rect = CGRectOffset(self.tabBar.frame, 0.0f, self.tabBar.frame.size.height);
  CGRect final_view_rect = [self growRect:self.view.frame
                                  byWidth:0.0f
                                andHeight:self.tabBar.frame.size.height];
  if (animate)
  {
    [UIView animateWithDuration:self.animator.linear_duration
                          delay:0.0f
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^
     {
       self.tabBar.frame = final_bar_rect;
       self.view.frame = final_view_rect;
       [self.view layoutIfNeeded];
     } completion:^(BOOL finished)
     {
       if (!finished)
       {
         self.tabBar.frame = final_bar_rect;
         self.view.frame = final_view_rect;
       }
     }];
  }
  else
  {
    self.tabBar.frame = final_bar_rect;
    self.view.frame = final_view_rect;
  }
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
  NSDictionary* bold_attrs = @{NSFontAttributeName: [UIFont fontWithName:@"HelveticaNeue-Bold" size:20.0f],
                               NSForegroundColorAttributeName: [UIColor whiteColor]};
  self.permission_view.message_label.text =
    NSLocalizedString(@"Tap \"OK\" to start sending\nyour photos and videos.", nil);
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
     self.selectedIndex = TabBarIndexSend;
   } failureBlock:^(NSError* error)
   {
     [self noGalleryAccessPopUp];
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
  if (position == TabBarIndexSend)
  {
    self.selection_indicator.frame = CGRectMake(0.0f, 0.0f, 0.0f, 0.0f);
    return;
  }
  NSUInteger count = self.viewControllers.count;
  self.selection_indicator.frame = CGRectMake(self.view.frame.size.width / count * position, 0.0f,
                                              self.view.frame.size.width / count, 1.0f);
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
