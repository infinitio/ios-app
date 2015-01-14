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
#import "InfinitSendTabIcon.h"
#import "InfinitTabAnimator.h"

#import <AssetsLibrary/AssetsLibrary.h>

@interface InfinitTabBarController ()

@property (nonatomic) NSUInteger last_index;
@property (nonatomic, strong) InfinitAccessGalleryView* permission_view;
@property (nonatomic, strong) UIView* selection_indicator;
@property (nonatomic, strong) InfinitSendTabIcon* send_tab_icon;
@property (nonatomic, strong) InfinitTabAnimator* animator;

@end

@implementation InfinitTabBarController
{
@private
  NSUInteger _send_index;
}

- (id)initWithCoder:(NSCoder*)aDecoder
{
  if (self = [super initWithCoder:aDecoder])
  {
    _animator = [[InfinitTabAnimator alloc] init];
  }
  return self;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  _send_index = 2;

  self.delegate = self;
  self.tabBar.tintColor = [InfinitColor colorFromPalette:ColorShamRock];

  [[UITabBar appearance] setBackgroundImage:[[UIImage alloc] init]];
  [[UITabBar appearance] setShadowImage:[[UIImage alloc] init]];

  UIView* shadow_line =
    [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.view.frame.size.width, 1.0f)];
  shadow_line.backgroundColor = [InfinitColor colorWithGray:186.0f];
  [self.tabBar addSubview:shadow_line];

  _selection_indicator =
    [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.view.frame.size.width / 5.0f, 1.0f)];
//  self.selection_indicator.backgroundColor = [InfinitColor colorFromPalette:ColorShamRock];
  self.selection_indicator.backgroundColor = [InfinitColor colorFromPalette:ColorBurntSienna];
  [self.tabBar addSubview:self.selection_indicator];

  _send_tab_icon = [[InfinitSendTabIcon alloc] initWithDiameter:67.0f];
  [self.tabBar addSubview:self.send_tab_icon];
  self.send_tab_icon.center = CGPointMake(self.view.frame.size.width / 2.0f,
                                          self.send_tab_icon.frame.size.height / 3.0f);
}

- (void)setSelectedIndex:(NSUInteger)selectedIndex
{
  if (selectedIndex == self.selectedIndex)
    return;
  [super setSelectedIndex:selectedIndex];
  if (selectedIndex != _send_index)
  {
    CGRect final_bar_rect = CGRectOffset(self.tabBar.frame, 0.0f, - self.tabBar.frame.size.height);
    CGRect final_view_rect = [self growRect:self.view.frame
                                    byWidth:0.0f
                                  andHeight:-self.tabBar.frame.size.height];
    [UIView animateWithDuration:self.animator.duration
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
  [self selectorToPosition:selectedIndex];
}

- (void)lastSelectedIndex
{
  self.selectedIndex = _last_index;
}

#pragma mark Delegate Functions

static BOOL asked_permission = NO;

- (BOOL)tabBarController:(UITabBarController*)tabBarController
shouldSelectViewController:(UIViewController*)viewController
{
  if ([self.viewControllers indexOfObject:viewController] == self.selectedIndex)
    return NO;
  _last_index = self.selectedIndex;
  if ([viewController.title isEqualToString:@"SETTINGS"])
  {
    [self dismissViewControllerAnimated:YES completion:nil];
    UIStoryboard* board = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
    UIViewController* login_controller =
      [board instantiateViewControllerWithIdentifier:@"welcome_controller"];
    [self presentViewController:login_controller animated:YES completion:nil];
    return NO;
  }
  else if ([viewController.title isEqualToString:@"SEND"])
  {
    CGRect final_bar_rect = CGRectOffset(self.tabBar.frame, 0.0f, self.tabBar.frame.size.height);
    CGRect final_view_rect = [self growRect:self.view.frame
                                    byWidth:0.0f
                                  andHeight:self.tabBar.frame.size.height];
    [UIView animateWithDuration:self.animator.duration
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
//    if ([ALAssetsLibrary authorizationStatus] == ALAuthorizationStatusNotDetermined)
//    {
//    if (!asked_permission)
//    {
//      asked_permission = YES;
//      [self loadGalleryPermissionView];
//      return NO;
//    }
//    }
//    else if ([ALAssetsLibrary authorizationStatus] == ALAuthorizationStatusDenied)
//    {
//      NSLog(@"xxx no permission for gallery");
//    }
  }
  NSUInteger index = [self.viewControllers indexOfObject:viewController];
  [self selectorToPosition:index];
  return YES;
}

- (id<UIViewControllerAnimatedTransitioning>)tabBarController:(UITabBarController*)tabBarController
           animationControllerForTransitionFromViewController:(UIViewController*)fromVC
                                             toViewController:(UIViewController*)toVC
{
  if ([toVC.title isEqualToString:@"SEND"])
  {
    self.animator.reverse = NO;
    self.animator.animation = AnimateCircleCover;
    self.animator.animation_center =
      CGPointMake(self.view.frame.size.width / 2.0f, self.view.frame.size.height -
                  self.send_tab_icon.frame.size.height / 3.0f);
  }
  else if ([fromVC.title isEqualToString:@"SEND"])
  {
    self.animator.reverse = YES;
    self.animator.animation = AnimateCircleCover;
    self.animator.animation_center =
      CGPointMake(self.view.frame.size.width / 2.0f, self.view.frame.size.height -
                  self.send_tab_icon.frame.size.height / 3.0f);
  }
  else
  {
    self.animator.animation = AnimateRightLeft;
    if ([self.viewControllers indexOfObject:toVC] > [self.viewControllers indexOfObject:fromVC])
      self.animator.reverse = NO;
    else
      self.animator.reverse = YES;
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
  self.permission_view.message_label.text =
    NSLocalizedString(@"Tap \"OK\" to start sending\nyour photos and videos", nil);
  UIAlertView* alert = [[UIAlertView alloc] initWithTitle:nil
                                                  message:@"Give me permission!"
                                                 delegate:nil
                                        cancelButtonTitle:nil
                                        otherButtonTitles:@"OK", nil];
  alert.delegate = self;
  [alert show];
}

- (void)alertView:(UIAlertView*)alertView
clickedButtonAtIndex:(NSInteger)buttonIndex
{
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
     self.selectedIndex = _send_index;
   } failureBlock:^(NSError* error)
   {
     if (error.code == ALAssetsLibraryAccessUserDeniedError)
     {
       NSLog(@"user denied access, code: %i",error.code);
     }
     else
     {
       NSLog(@"Other error code: %i",error.code);
     }
   }];
}

- (void)selectorToPosition:(NSInteger)position
{
  if (position == _send_index)
  {
    self.selection_indicator.frame = CGRectMake(0.0f, 0.0f, 0.0f, 0.0f);
    return;
  }
  CGFloat count = self.viewControllers.count;
  self.selection_indicator.frame = CGRectMake(self.view.frame.size.width / count * position, 0.0f,
                                              self.view.frame.size.width / count, 1.0f);
}

#pragma mark Helpers

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
