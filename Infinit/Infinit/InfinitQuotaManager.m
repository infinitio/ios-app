//
//  InfinitQuotaManager.m
//  Infinit
//
//  Created by Christopher Crone on 19/08/15.
//  Copyright © 2015 Infinit. All rights reserved.
//

#import "InfinitQuotaManager.h"

#import "AppDelegate.h"
#import "InfinitQuotaOverlayViewController.h"

#import <Gap/InfinitPeerTransactionManager.h>

@interface InfinitQuotaManager () <InfinitQuotaOverlayProtocol>

@property (nonatomic, readonly) InfinitQuotaOverlayViewController* overlay_controller;
@property dispatch_once_t overlay_token;

@property BOOL showing_overlay;

@end

static InfinitQuotaManager* _instance = nil;
static dispatch_once_t _instance_token = 0;

@implementation InfinitQuotaManager

@synthesize overlay_controller = _overlay_controller;

#pragma mark - Init

- (instancetype)_init
{
  NSAssert(_instance == nil, @"Use sharedInstance.");
  if (self = [super init])
  {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didReceiveMemoryWarning) 
                                                 name:UIApplicationDidReceiveMemoryWarningNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(ghostDownloadLimited:)
                                                 name:INFINIT_GHOST_DOWNLOAD_LIMITED
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(sendToSelfLimited:) 
                                                 name:INFINIT_SEND_TO_SELF_LIMITED
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(transferSizeLimited:) 
                                                 name:INFINIT_PEER_TRANSFER_SIZE_LIMITED
                                               object:nil];
  }
  return self;
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

+ (instancetype)sharedInstance
{
  dispatch_once(&_instance_token, ^
  {
    _instance = [[self alloc] _init];
  });
  return _instance;
}

#pragma mark - External

+ (void)start
{
  [self sharedInstance];
}

+ (void)showSendToSelfLimitOverlay
{
  [[self sharedInstance] showSendToSelfLimitOverlay];
}

- (void)showSendToSelfLimitOverlay
{
  if (self.showing_overlay)
    return;
  [self.overlay_controller configureForSendToSelfLimit];
  [self showOverlayController];
}

#pragma mark - Callbacks

- (void)ghostDownloadLimited:(NSNotification*)notification
{
  dispatch_async(dispatch_get_main_queue(), ^
  {
    if (self.showing_overlay)
      return;
    InfinitPeerTransaction* transaction =
      [InfinitPeerTransactionManager transactionWithId:notification.userInfo[kInfinitTransactionId]];
    if (!transaction)
      return;
    [self.overlay_controller configureForGhostDownloadLimit:transaction.recipient];
    [self showOverlayController];
  });
}

- (void)sendToSelfLimited:(NSNotification*)notification
{
  dispatch_async(dispatch_get_main_queue(), ^
  {
    [self showSendToSelfLimitOverlay];
  });
}

- (void)transferSizeLimited:(NSNotification*)notification
{
  dispatch_async(dispatch_get_main_queue(), ^
  {
    if (self.showing_overlay)
      return;
    [self.overlay_controller configureForTransferSizeLimit];
    [self showOverlayController];
  });
}

#pragma mark - InfinitQuotaOverlayProtocol

- (void)quotaOverlayWantsClose:(InfinitQuotaOverlayViewController*)sender
{
  UIView* view = sender.view;
  if (view == nil)
    return;
  UIViewController* root_controller =
    ((AppDelegate*)[UIApplication sharedApplication].delegate).root_controller;
  [UIView animateWithDuration:0.3f
                   animations:^
   {
     view.alpha = 0.0f;
   } completion:^(BOOL finished)
   {
     root_controller.view.userInteractionEnabled = YES;
     [view removeFromSuperview];
     self.showing_overlay = NO;
   }];
}

#pragma mark - Helpers

- (InfinitQuotaOverlayViewController*)overlay_controller
{
  dispatch_once(&_overlay_token, ^
  {
    _overlay_controller = [[InfinitQuotaOverlayViewController alloc] init];
    _overlay_controller.delegate = self;
  });
  return _overlay_controller;
}

- (void)showOverlayController
{
  self.showing_overlay = YES;
  UIViewController* root_controller =
    ((AppDelegate*)[UIApplication sharedApplication].delegate).root_controller;
  root_controller.view.userInteractionEnabled = NO;
  UIView* view = self.overlay_controller.view;
  view.alpha = 0.0f;
  view.frame = [UIScreen mainScreen].bounds;
  [[UIApplication sharedApplication].keyWindow addSubview:view];
  [[UIApplication sharedApplication].keyWindow bringSubviewToFront:view];
  [UIView animateWithDuration:0.3f
                   animations:^
   {
     view.alpha = 1.0f;
   } completion:^(BOOL finished)
   {
     if (!finished)
       view.alpha = 1.0f;
   }];
}

#pragma mark - Memory Warning

- (void)didReceiveMemoryWarning
{
  if (self.showing_overlay)
    return;
  _overlay_token = 0;
  _overlay_controller = nil;
}

@end
