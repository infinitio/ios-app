//
//  InfinitHomeViewController.m
//  Infinit
//
//  Created by Michael Dee on 12/30/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import "InfinitHomeViewController.h"

#import "InfinitApplicationSettings.h"
#import "InfinitConstants.h"
#import "InfinitDownloadFolderManager.h"
#import "InfinitFilesMultipleViewController.h"
#import "InfinitFilePreviewController.h"
#import "InfinitHomeItem.h"
#import "InfinitHomePeerTransactionCell.h"
#import "InfinitHomeEmptyOverlay.h"
#import "InfinitHomeFeedbackViewController.h"
#import "InfinitHomeOnboardingCell.h"
#import "InfinitHomeRatingCell.h"
#import "InfinitHostDevice.h"
#import "InfinitMainSplitViewController_iPad.h"
#import "InfinitMetricsManager.h"
#import "InfinitOfflineOverlay.h"
#import "InfinitRatingManager.h"
#import "InfinitResizableNavigationBar.h"
#import "InfinitSendRecipientsController.h"
#import "InfinitTabBarController.h"
#import "InfinitUploadThumbnailManager.h"

#import <Gap/InfinitColor.h>
#import <Gap/InfinitDataSize.h>
#import <Gap/InfinitDeviceManager.h>
#import <Gap/InfinitPeerTransactionManager.h>
#import <Gap/InfinitUserManager.h>

#import "UIImage+Rounded.h"

@interface InfinitHomeViewController () <InfinitHomePeerTransactionCellProtocol,
                                         UICollectionViewDataSource,
                                         UICollectionViewDelegate,
                                         UICollectionViewDelegateFlowLayout,
                                         UIGestureRecognizerDelegate>

@property (nonatomic, weak) IBOutlet UICollectionView* collection_view;

@property (atomic, readonly) NSMutableArray* data;
@property (nonatomic, strong) UIView* onboarding_view;
@property (nonatomic, strong) UIView* no_activity_view;
@property (nonatomic, weak) InfinitHomeRatingCell* rating_cell;
@property (nonatomic, readonly) BOOL show_rate_us;

@property (nonatomic, readonly) UIImageView* cell_image_view;
@property (nonatomic, weak, readonly) UICollectionViewCell* moving_cell;
@property (nonatomic, readonly) UIOffset touch_offset;
@property (nonatomic, readonly) UIDynamicAnimator* dynamic_animator;
@property (nonatomic, readonly) UIAttachmentBehavior* anchor_behavior;
@property (nonatomic) CGPoint last_location;
@property (nonatomic) NSTimeInterval last_time;

@property (nonatomic, readonly) NSMutableDictionary* round_avatar_cache;
@property (nonatomic, readonly) NSMutableDictionary* round_avatar_device_cache;

@property (atomic, readwrite) BOOL previewing_files;
@property (atomic, readwrite) BOOL sending;

// Onboarding
@property (atomic, readwrite) BOOL notification_onboarded;
@property (atomic, readwrite) BOOL swipe_onboarded;
@property (atomic, readwrite) BOOL peer_send_onboarded;
@property (nonatomic, readonly) NSString* onboarding_peer_name;
@property (atomic, readwrite) BOOL ghost_send_onboarded;
@property (nonatomic, readonly) NSString* onboarding_ghost_name;
@property (atomic, readwrite) BOOL self_send_onboarded;
@property (atomic, readwrite) BOOL background_onboarded;
@property (atomic, readonly) NSMutableArray* onboarding_model;

// Extension
@property (nonatomic, readonly) NSString* extension_files_uuid;
@property (nonatomic, readonly) NSArray* extension_internal_files;

@end

static CGSize _avatar_size = {55.0f, 55.0f};
static NSUInteger _background_onboard_size = 5 * 1000 * 1000;

@implementation InfinitHomeViewController
{
@private
  NSString* _onboarding_cell_id;
  NSString* _peer_transaction_cell_id;
  NSString* _rating_cell_id;

  NSTimer* _progress_timer;
  NSTimeInterval _update_interval;
  NSMutableArray* _running_transactions;
}

- (void)didReceiveMemoryWarning
{
  [self.round_avatar_cache removeAllObjects];
  [self.round_avatar_device_cache removeAllObjects];
  [super didReceiveMemoryWarning];
}

#pragma mark - Init

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
  _peer_transaction_cell_id = @"home_peer_transaction_cell";
  _onboarding_cell_id = @"home_onboarding_cell";
  _rating_cell_id = @"home_rating_cell";
  _update_interval = 0.5f;
  self.collection_view.alwaysBounceVertical = YES;
  self.collection_view.allowsMultipleSelection = NO;
  [super viewDidLoad];
  self.navigationItem.titleView =
    [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icon-logo-red"]];
  UINib* transaction_cell_nib =
    [UINib nibWithNibName:NSStringFromClass(InfinitHomePeerTransactionCell.class) bundle:nil];
  [self.collection_view registerNib:transaction_cell_nib
        forCellWithReuseIdentifier:_peer_transaction_cell_id];
  UINib* onboarding_cell_nib =
    [UINib nibWithNibName:NSStringFromClass(InfinitHomeOnboardingCell.class) bundle:nil];
  [self.collection_view registerNib:onboarding_cell_nib
        forCellWithReuseIdentifier:_onboarding_cell_id];
  UINib* rating_cell_nib = [UINib nibWithNibName:NSStringFromClass(InfinitHomeRatingCell.class)
                                          bundle:nil];
  [self.collection_view registerNib:rating_cell_nib forCellWithReuseIdentifier:_rating_cell_id];
  [self.navigationController.navigationBar setBackgroundImage:[[UIImage alloc] init]
                                                forBarMetrics:UIBarMetricsDefault];
  self.navigationController.navigationBar.shadowImage = [[UIImage alloc] init];
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  if (self.cell_image_view != nil)
  {
    [self.cell_image_view removeFromSuperview];
    _cell_image_view = nil;
  }
  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
  {
    InfinitTabBarController* tab_controller = (InfinitTabBarController*)self.tabBarController;
    if (self.sending)
      [tab_controller setTabBarHidden:NO animated:NO];
    else
      [tab_controller setTabBarHidden:NO animated:YES withDelay:0.2f];
    _sending = NO;
    InfinitResizableNavigationBar* nav_bar =
      (InfinitResizableNavigationBar*)self.navigationController.navigationBar;
    [UIView animateWithDuration:(animated ? 0.3f : 0.0f)
                     animations:^
    {
      nav_bar.large = NO;
      nav_bar.shadowImage = [[UIImage alloc] init];
      [[UIApplication sharedApplication] setStatusBarHidden:NO
                                              withAnimation:UIStatusBarAnimationSlide];
      nav_bar.barTintColor = [InfinitColor colorFromPalette:InfinitPaletteColorLightGray];
    }];
  }
  if (self.current_status && !self.previewing_files)
    [self refreshContents];
  else if (!self.previewing_files)
  {
    [self.collection_view scrollRectToVisible:CGRectMake(0.0f, 0.0f, 1.0f, 1.0f) animated:NO];
  }
}

- (void)viewDidAppear:(BOOL)animated
{
  self.previewing_files = NO;
  [super viewDidAppear:animated];
}

- (void)refreshContents
{
  _show_rate_us = [InfinitRatingManager sharedInstance].show_transaction_rating;
  [self loadTransactions];
  NSInteger count =
    [[InfinitPeerTransactionManager sharedInstance] transactionsIncludingArchived:YES
                                                                   thisDeviceOnly:YES].count;
  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
  {
    if (count == 0)
      [self showOnboardingArrow];
  }

  if (self.data.count == 0 && self.swipe_onboarded && self.notification_onboarded)
  {
    [self showNoActivityView];
  }
  else if (self.no_activity_view != nil)
  {
    [self.no_activity_view removeFromSuperview];
    self.no_activity_view = nil;
  }
}

- (void)loadTransactions
{
  @synchronized(self.data)
  {
    NSArray* peer_transactions =
      [[InfinitPeerTransactionManager sharedInstance] transactionsIncludingArchived:NO
                                                                     thisDeviceOnly:YES];
    if (self.data == nil)
      _data = [NSMutableArray array];
    else
      [self.data removeAllObjects];
    // Onboarding variables. If any given one is true, we must add the cell to the onboarding model.
    BOOL add_background = NO;
    BOOL add_self = NO;
    BOOL add_peer = NO;
    _onboarding_peer_name = nil;
    BOOL add_ghost = NO;
    _onboarding_ghost_name = nil;
    for (InfinitTransaction* transaction in peer_transactions)
    {
      InfinitHomeItem* item = [[InfinitHomeItem alloc] initWithTransaction:transaction];
      if ([transaction isKindOfClass:InfinitPeerTransaction.class])
      {
        InfinitPeerTransaction* peer_transaction = (InfinitPeerTransaction*)transaction;
        if (!self.background_onboarded &&
            peer_transaction.size.unsignedIntegerValue > _background_onboard_size)
        {
          add_background = YES;
        }
        if (!self.self_send_onboarded && peer_transaction.from_device &&
            peer_transaction.sender.is_self && peer_transaction.recipient.is_self)
        {
          add_self = YES;
        }
        if (!self.peer_send_onboarded &&
            !peer_transaction.recipient.is_self && !peer_transaction.recipient.ghost)
        {
          if (self.onboarding_peer_name == nil)
            _onboarding_peer_name = [peer_transaction.recipient.fullname copy];
          add_peer = YES;
        }
        if (!self.ghost_send_onboarded &&
            !peer_transaction.recipient.is_self && peer_transaction.recipient.ghost)
        {
          if (self.onboarding_ghost_name == nil)
            _onboarding_ghost_name = [peer_transaction.recipient.fullname copy];
          add_ghost = YES;
        }
      }
      [self.data addObject:item];
    }
    if (self.onboarding_model == nil)
      _onboarding_model = [NSMutableArray array];
    else
      [self.onboarding_model removeAllObjects];
    if (add_background)
    {
      InfinitHomeOnboardingItem* item =
        [InfinitHomeOnboardingItem initWithType:InfinitHomeOnboardingCellBackground];
      [self.onboarding_model addObject:item];
    }
    if (add_self)
    {
      InfinitHomeOnboardingItem* item =
        [InfinitHomeOnboardingItem initWithType:InfinitHomeOnboardingCellSelfSent];
      [self.onboarding_model addObject:item];
    }
    if (add_peer)
    {
      InfinitHomeOnboardingItem* item =
        [InfinitHomeOnboardingItem initWithType:InfinitHomeOnboardingCellPeerSent];
      [self.onboarding_model addObject:item];
    }
    if (add_ghost)
    {
      InfinitHomeOnboardingItem* item =
        [InfinitHomeOnboardingItem initWithType:InfinitHomeOnboardingCellGhostSent];
      [self.onboarding_model addObject:item];
    }

    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(peerTransactionUpdated:)
                                                 name:INFINIT_PEER_TRANSACTION_STATUS_NOTIFICATION
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(peerTransactionAdded:)
                                                 name:INFINIT_NEW_PEER_TRANSACTION_NOTIFICATION
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(userAvatarUpdated:)
                                                 name:INFINIT_USER_AVATAR_NOTIFICATION
                                               object:nil];
    [self.collection_view reloadData];
    [self updateRunningTransactions];
  }
}

- (void)showOnboardingArrow
{
  if (self.onboarding_view == nil)
  {
    UINib* onboarding_nib = [UINib nibWithNibName:@"InfinitHomeOnboardingView" bundle:nil];
    self.onboarding_view = [[onboarding_nib instantiateWithOwner:self options:nil] firstObject];
    [self.view addSubview:self.onboarding_view];
  }
  CGFloat height = self.onboarding_view.bounds.size.height + 30.0f;
  CGFloat y =
  [UIScreen mainScreen].bounds.size.height - height - self.tabBarController.tabBar.bounds.size.height;
  CGRect frame =
    CGRectMake(0.0f,
               y,
               self.view.bounds.size.width,
               height);
  self.onboarding_view.frame = [self.view convertRect:frame fromView:self.view.superview];
}

- (void)showNoActivityView
{
  if (self.no_activity_view == nil)
  {
    UINib* activity_nib = [UINib nibWithNibName:NSStringFromClass(InfinitHomeEmptyOverlay.class)
                                         bundle:nil];
    self.no_activity_view = [[activity_nib instantiateWithOwner:self options:nil] firstObject];
    self.no_activity_view.translatesAutoresizingMaskIntoConstraints = NO;
    self.no_activity_view.backgroundColor =
      [InfinitColor colorFromPalette:InfinitPaletteColorLightGray];
    [self.view addSubview:self.no_activity_view];
    NSDictionary* views = @{@"view": self.no_activity_view};
    NSArray* h_constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[view]|"
                                                                     options:0
                                                                     metrics:nil
                                                                       views:views];
    NSArray* v_constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[view]|"
                                                                     options:0
                                                                     metrics:nil
                                                                       views:views];
    [self.view addConstraints:h_constraints];
    [self.view addConstraints:v_constraints];
    if (self.onboarding_view && ![InfinitHostDevice smallScreen])
      [self.view bringSubviewToFront:self.onboarding_view];
  }
}

- (void)updateRunningTransactions
{
  @synchronized(self.data)
  {
    NSUInteger row = 0;
    if (_running_transactions == nil)
      _running_transactions = [NSMutableArray array];
    else
      [_running_transactions removeAllObjects];
    for (InfinitHomeItem* item in self.data)
    {
      if (item.transaction != nil && item.transaction.status == gap_transaction_transferring)
      {
        NSIndexPath* path = [NSIndexPath indexPathForRow:row inSection:[self topSection] ? 1 : 0];
        [_running_transactions addObject:path];
      }
    }
    if (_running_transactions.count > 0 && _progress_timer == nil)
    {
      _progress_timer = [NSTimer timerWithTimeInterval:_update_interval
                                                target:self 
                                              selector:@selector(updateProgress)
                                              userInfo:nil
                                               repeats:YES];
      [[NSRunLoop mainRunLoop] addTimer:_progress_timer forMode:NSDefaultRunLoopMode];
    }
    else if (_running_transactions == 0)
    {
      [_progress_timer invalidate];
      _progress_timer = nil;
    }
  }
}

- (void)updateProgress
{
  if (_running_transactions.count == 0)
  {
    [_progress_timer invalidate];
    _progress_timer = nil;
    return;
  }
  for (NSIndexPath* path in _running_transactions)
  {
    if (![self.collection_view.indexPathsForVisibleItems containsObject:path])
      continue;
    UICollectionViewCell* cell = [self.collection_view cellForItemAtIndexPath:path];
    if ([cell isKindOfClass:InfinitHomePeerTransactionCell.class])
    {
      InfinitHomePeerTransactionCell* peer_cell = (InfinitHomePeerTransactionCell*)cell;
      [peer_cell updateProgressOverDuration:_update_interval];
    }
  }
}

- (void)viewWillDisappear:(BOOL)animated
{
  if (!self.previewing_files)
    [[NSNotificationCenter defaultCenter] removeObserver:self];
  [_progress_timer invalidate];
  _progress_timer = nil;
  [super viewWillDisappear:animated];
  if (self.cell_image_view)
  {
    [self.cell_image_view removeFromSuperview];
    _cell_image_view = nil;
  }
}

#pragma mark - General

- (void)scrollToTop
{
  [self.collection_view scrollRectToVisible:CGRectMake(0.0f, 0.0f, 1.0f, 1.0f) animated:YES];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView*)scrollView
{
  [self updateRunningTransactions];
}

- (void)scrollViewWillBeginDragging:(UIScrollView*)scrollView
{
  if (_running_transactions.count > 0 && _progress_timer.isValid)
  {
    [_progress_timer invalidate];
    _progress_timer = nil;
  }
  for (NSIndexPath* index in _running_transactions)
  {
    InfinitHomePeerTransactionCell* cell =
      (InfinitHomePeerTransactionCell*)[self.collection_view cellForItemAtIndexPath:index];
    [cell pauseAnimations];
  }
  if (_running_transactions)
    [_running_transactions removeAllObjects];
}

#pragma mark - Collection View Protocol

- (void)collectionView:(UICollectionView*)collectionView
didSelectItemAtIndexPath:(NSIndexPath*)indexPath
{
  UICollectionViewCell* cell = [self.collection_view cellForItemAtIndexPath:indexPath];
  if ([cell isKindOfClass:InfinitHomePeerTransactionCell.class])
  {
    InfinitHomeItem* item = self.data[indexPath.row];
    [self setExpanded:!item.expanded forIndexPath:indexPath];
  }
}

- (void)setExpanded:(BOOL)expanded
       forIndexPath:(NSIndexPath*)index_path
{
  InfinitHomeItem* item = self.data[index_path.row];
  item.expanded = expanded;
  InfinitHomePeerTransactionCell* peer_cell =
    (InfinitHomePeerTransactionCell*)[self.collection_view cellForItemAtIndexPath:index_path];
  peer_cell.expanded = item.expanded;
  [self.collection_view.collectionViewLayout invalidateLayout];
  if (![self.collection_view.indexPathsForVisibleItems containsObject:index_path])
    return;
  CGSize new_size = [self collectionView:self.collection_view
                                  layout:self.collection_view.collectionViewLayout
                  sizeForItemAtIndexPath:index_path];
  peer_cell.layer.shadowPath = nil;
  [UIView animateWithDuration:0.3f
                        delay:0.0f
       usingSpringWithDamping:0.8f
        initialSpringVelocity:20.0f
                      options:0
                   animations:^
   {
     peer_cell.frame = CGRectMake(peer_cell.frame.origin.x,
                                  peer_cell.frame.origin.y,
                                  new_size.width,
                                  new_size.height);
     [peer_cell layoutIfNeeded];
   } completion:^(BOOL finished)
   {
     peer_cell.expanded = item.expanded;
     peer_cell.layer.shadowPath =
       [UIBezierPath bezierPathWithRoundedRect:peer_cell.bounds cornerRadius:3.0f].CGPath;
   }];
}

#pragma mark - Data Source

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView*)collectionView
{
  NSInteger res = 0;
  if (self.data.count > 0)
    res++;
  if ([self bottomSection])
    res++;
  if ([self topSection])
    res++;
  return res;
}


- (NSInteger)collectionView:(UICollectionView*)collectionView
     numberOfItemsInSection:(NSInteger)section
{
  if ([self topSection] && section == 0)
  {
    NSInteger res = self.onboarding_model.count;
    if (self.show_rate_us)
      res += 1;
    return res;
  }
  else if ((![self topSection] && self.data.count > 0 && section == 0) ||
           ([self topSection] && self.data.count > 0 && section == 1))
  {
    return self.data.count;
  }
  else
  {
    NSInteger res = 0;
    if (!self.notification_onboarded)
      res += 1;
    if (!self.swipe_onboarded)
      res += 1;
    return res;
  }
}


- (UICollectionViewCell*)collectionView:(UICollectionView*)collectionView
                 cellForItemAtIndexPath:(NSIndexPath*)indexPath
{
  UICollectionViewCell* res = nil;
  if ([self topSection] && indexPath.section == 0)
  {
    if (indexPath.row == self.onboarding_model.count)
    {
      InfinitHomeRatingCell* cell =
        [self.collection_view dequeueReusableCellWithReuseIdentifier:_rating_cell_id
                                                        forIndexPath:indexPath];
      [cell.positive_button addTarget:self
                               action:@selector(positiveButtonTapped:)
                     forControlEvents:UIControlEventTouchUpInside];
      [cell.negative_button addTarget:self
                               action:@selector(negativeButtonTapped:)
                     forControlEvents:UIControlEventTouchUpInside];
      self.rating_cell = cell;
      res = cell;
    }
    else
    {
      InfinitHomeOnboardingCell* cell =
        [self.collection_view dequeueReusableCellWithReuseIdentifier:_onboarding_cell_id
                                                        forIndexPath:indexPath];
      InfinitHomeOnboardingItem* item = self.onboarding_model[indexPath.row];
      NSString* text = nil;
      NSInteger lines = 0;
      NSRange gray_range = NSMakeRange(NSNotFound, 0);
      switch (item.type)
      {
        case InfinitHomeOnboardingCellBackground:
          text = NSLocalizedString(@"Rest assured! Closing Infinit\n"
                                   "won't stop your transfer.", nil);
          lines = 2;
          break;
        case InfinitHomeOnboardingCellGhostSent:
          if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
          {
            text =
              [NSString stringWithFormat:NSLocalizedString(@"All set! A message will\n"
                                                           "be sent to\n"
                                                           "%@.", nil),
               self.onboarding_ghost_name];
            lines = 3;
          }
          else
          {
            text =
              [NSString stringWithFormat:NSLocalizedString(@"All set! A message will be sent\n"
                                                           "to %@.", nil),
               self.onboarding_ghost_name];
            lines = 2;
          }
          gray_range = [text rangeOfString:self.onboarding_ghost_name];
          break;
        case InfinitHomeOnboardingCellPeerSent:
          text = [NSString stringWithFormat:NSLocalizedString(@"We'll let you know\n"
                                                              "when %@\n"
                                                              "receives your files.", nil),
                  self.onboarding_peer_name];
          gray_range = [text rangeOfString:self.onboarding_peer_name];
          lines = 3;
          break;
        case InfinitHomeOnboardingCellSelfSent:
          text = NSLocalizedString(@"Install Infinit on another\n"
                                   "device to retrieve your\n"
                                   "files.", nil);
          lines = 3;
          break;

        default:
          break;
      }
      [cell setType:item.type withText:text grayRange:gray_range numberOfLines:lines];
      res = cell;
    }
  }
  else if ((![self topSection] && self.data.count > 0 && indexPath.section == 0) ||
           ([self topSection] && self.data.count > 0 && indexPath.section == 1))
  {
    InfinitHomeItem* item = self.data[indexPath.row];
    if (item.transaction != nil && [item.transaction isKindOfClass:InfinitPeerTransaction.class])
    {
      InfinitPeerTransaction* peer_transaction = (InfinitPeerTransaction*)item.transaction;
      InfinitHomePeerTransactionCell* cell;
      UIImage* avatar = nil;
      if (peer_transaction.sender.is_self && peer_transaction.recipient.is_self)
      {
        NSString* device_id = nil;
        if (peer_transaction.from_device)
          device_id = peer_transaction.recipient_device;
        else
          device_id = peer_transaction.sender_device_id;
        InfinitDevice* device = [[InfinitDeviceManager sharedInstance] deviceWithId:device_id];
        if (device != nil)
        {
          if (self.round_avatar_device_cache == nil)
            _round_avatar_device_cache = [NSMutableDictionary dictionary];
          avatar = [self.round_avatar_device_cache objectForKey:@(device.type)];
          if (avatar == nil)
          {
            UIImage* raw_image = nil;
            switch (device.type)
            {
              case InfinitDeviceTypeAndroid:
                raw_image = [UIImage imageNamed:@"icon-device-android-avatar"];
                break;
              case InfinitDeviceTypeiPad:
              case InfinitDeviceTypeiPhone:
              case InfinitDeviceTypeiPod:
                raw_image = [UIImage imageNamed:@"icon-device-ios-avatar"];
                break;
              case InfinitDeviceTypeMacLaptop:
              case InfinitDeviceTypeMacDesktop:
                raw_image = [UIImage imageNamed:@"icon-device-mac-avatar"];
                break;
              default:
                raw_image = [UIImage imageNamed:@"icon-device-windows-avatar"];
                break;
            }
            avatar = [raw_image infinit_circularMaskOfSize:_avatar_size];
            [self.round_avatar_device_cache setObject:avatar forKey:@(device.type)];
          }
        }
      }
      if (avatar == nil)
      {
        if (self.round_avatar_cache == nil)
          _round_avatar_cache = [NSMutableDictionary dictionary];
        avatar = [self.round_avatar_cache objectForKey:peer_transaction.other_user.id_];
        if (avatar == nil)
        {
          avatar = [peer_transaction.other_user.avatar infinit_circularMaskOfSize:_avatar_size];
          [self.round_avatar_cache setObject:avatar forKey:peer_transaction.other_user.id_];
        }
      }
      cell = [self.collection_view dequeueReusableCellWithReuseIdentifier:_peer_transaction_cell_id
                                                             forIndexPath:indexPath];
      [cell setUpWithDelegate:self
                  transaction:peer_transaction
                     expanded:item.expanded
                       avatar:avatar];
      res = cell;
    }
  }
  else
  {
    InfinitHomeOnboardingCell* cell =
      [self.collection_view dequeueReusableCellWithReuseIdentifier:_onboarding_cell_id
                                                      forIndexPath:indexPath];
    InfinitHomeOnboardingCellType type;
    NSString* text = nil;
    if (indexPath.row == 0 && !self.notification_onboarded)
    {
      type = InfinitHomeOnboardingCellNotifications;
      if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
      {
        text = NSLocalizedString(@"Your current transfers and\n"
                                 "notifications will show\nup here.", nil);
      }
      else
      {
        text = NSLocalizedString(@"Your current transfers and\n"
                                 "notifications will show up here.", nil);
      }
    }
    else
    {
      type = InfinitHomeOnboardingCellSwipe;
      text = NSLocalizedString(@"Swipe the cards left or right\n"
                               "to remove them.", nil);
    }
    [cell setType:type withText:text grayRange:NSMakeRange(NSNotFound, 0) numberOfLines:3];
    res = cell;
  }
  return res;
}

#pragma mark – UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView*)collectionView
                  layout:(UICollectionViewLayout*)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath*)indexPath
{
  CGFloat width = self.view.bounds.size.width - 26.0f;
  CGFloat height = 100.0f;
  if ([self topSection] && indexPath.section == 0) // Top onboarding and/or rating
  {
    if (indexPath.row == self.onboarding_model.count)
    {
      height = 100.0f;
    }
    else
    {
      InfinitHomeOnboardingItem* item = self.onboarding_model[indexPath.row];
      switch (item.type)
      {
        case InfinitHomeOnboardingCellBackground:
          height = 80.0f;
          break;
        case InfinitHomeOnboardingCellGhostSent:
        case InfinitHomeOnboardingCellPeerSent:
        case InfinitHomeOnboardingCellSelfSent:
          height = 100.0f;
          break;

        default:
          break;
      }
    }
  }
  else if ((![self topSection] && self.data.count > 0 && indexPath.section == 0) ||
           ([self topSection] && self.data.count > 0 && indexPath.section == 1)) // Peer Transaction.
  {
    CGFloat file_h = 75.0f + 10.0f;
    CGFloat status_h = 45.0f;
    CGFloat button_h = 46.0f; // Includes line above buttons.
    InfinitHomeItem* item = self.data[indexPath.row];
    InfinitPeerTransaction* transaction = nil;
    if (item.transaction != nil && [item.transaction isKindOfClass:InfinitPeerTransaction.class])
      transaction = (InfinitPeerTransaction*)item.transaction;
    BOOL expanded = item.expanded;
    switch (transaction.status)
    {
      case gap_transaction_new:
        // Can only be this device who is sender.
      case gap_transaction_on_other_device:
        if (expanded)
        {
          height += status_h + button_h;
          if (transaction.from_device)
            height += (transaction.files.count > 3 ? 2 * file_h : file_h);
        }
        break;
      case gap_transaction_waiting_accept:
        if (transaction.receivable && expanded)
        {
          height += (transaction.files.count > 3 ? 2 * file_h : file_h) + status_h + button_h;
        }
        else if (transaction.receivable)
        {
          height += button_h;
        }
        else if (transaction.sender.is_self && expanded)
        {
          height += status_h + button_h;
          if (transaction.from_device)
            height += (transaction.files.count > 3 ? 2 * file_h : file_h);
        }
        break;

      case gap_transaction_waiting_data:
      case gap_transaction_connecting:
      case gap_transaction_transferring:
      case gap_transaction_paused:
        if (transaction.to_device && expanded)
        {
          height += (transaction.files.count > 3 ? 2 * file_h : file_h) + status_h + button_h;
        }
        else if (expanded)
        {
          height += status_h + button_h;
          if (transaction.from_device)
            height += (transaction.files.count > 3 ? 2 * file_h : file_h);
        }
        break;

      case gap_transaction_cloud_buffered:
      case gap_transaction_rejected:
      case gap_transaction_finished:
      case gap_transaction_failed:
      case gap_transaction_canceled:
        if (expanded)
        {
          height += status_h;
          if (transaction.from_device)
            height += (transaction.files.count > 3 ? 2 * file_h : file_h);
        }
        if (transaction.status == gap_transaction_finished && transaction.to_device && expanded)
        {
          InfinitDownloadFolderManager* manager = [InfinitDownloadFolderManager sharedInstance];
          InfinitFolderModel* folder =
            [manager completedFolderForTransactionMetaId:transaction.meta_id];
          NSUInteger file_count = transaction.files.count;
          if (folder)
          {
            file_count = folder.files.count;
            height += button_h;
          }
          height += (file_count > 3 ? 2 * file_h : file_h);
        }
        break;

      default:
        break;
    }
  }
  else // Initial onboarding
  {
    switch (indexPath.row)
    {
      case 0:
        height = 110.0f;
        break;
      case 1:
        height = 94.0f;
        break;

      default:
        break;
    }
  }
  return CGSizeMake(width, height);
}

- (UIEdgeInsets)collectionView:(UICollectionView*)collectionView
                        layout:(UICollectionViewLayout*)collectionViewLayout
        insetForSectionAtIndex:(NSInteger)section
{
  return UIEdgeInsetsMake(20.0f, 0.0f, 0.0f, 0.0f);
}

#pragma mark - Transaction Handling

- (void)peerTransactionAdded:(NSNotification*)notification
{
  NSNumber* transaction_id = notification.userInfo[kInfinitTransactionId];
  InfinitPeerTransaction* peer_transaction =
    [[InfinitPeerTransactionManager sharedInstance] transactionWithId:transaction_id];
  if (!peer_transaction.concerns_device || peer_transaction.archived)
    return;
  InfinitHomeItem* item = [[InfinitHomeItem alloc] initWithTransaction:peer_transaction];
  [self addItem:item];
  if (self.onboarding_view != nil)
  {
    [self removeOnboardingView];
  }
  if (self.no_activity_view != nil)
  {
    [self removeNoActivityView];
  }
}

- (void)addItem:(InfinitHomeItem*)item
{
  @synchronized(self.data)
  {
    if ([self.data containsObject:item])
      return;
    [self.collection_view.collectionViewLayout invalidateLayout];
    if (self.data.count == 0)
    {
      if (item.transaction && [item.transaction isKindOfClass:InfinitPeerTransaction.class])
      {
        InfinitPeerTransaction* transaction = (InfinitPeerTransaction*)item.transaction;
        if (self.onboarding_model == nil)
          _onboarding_model = [NSMutableArray array];
        else
          [self.onboarding_model removeAllObjects];
        if (!self.background_onboarded &&
            transaction.size.unsignedIntegerValue > _background_onboard_size)
        {
          InfinitHomeOnboardingItem* item =
            [InfinitHomeOnboardingItem initWithType:InfinitHomeOnboardingCellBackground];
          [self.onboarding_model addObject:item];
        }
        if (!self.self_send_onboarded && transaction.from_device &&
            transaction.sender.is_self && transaction.recipient.is_self)
        {
          InfinitHomeOnboardingItem* item =
            [InfinitHomeOnboardingItem initWithType:InfinitHomeOnboardingCellSelfSent];
          [self.onboarding_model addObject:item];
        }
        if (!self.peer_send_onboarded &&
            !transaction.recipient.is_self && !transaction.recipient.ghost)
        {
          if (self.onboarding_peer_name == nil)
            _onboarding_peer_name = [transaction.recipient.fullname copy];
          InfinitHomeOnboardingItem* item =
            [InfinitHomeOnboardingItem initWithType:InfinitHomeOnboardingCellPeerSent];
          [self.onboarding_model addObject:item];
        }
        if (!self.ghost_send_onboarded &&
            !transaction.recipient.is_self && transaction.recipient.ghost)
        {
          if (self.onboarding_ghost_name == nil)
            _onboarding_ghost_name = [transaction.recipient.fullname copy];
          InfinitHomeOnboardingItem* item =
            [InfinitHomeOnboardingItem initWithType:InfinitHomeOnboardingCellGhostSent];
          [self.onboarding_model addObject:item];
        }
      }
      [self.data addObject:item];
      [self.collection_view reloadData];
      [self updateRunningTransactions];
    }
    else
    {
      [self.collection_view performBatchUpdates:^
       {
         [self.data insertObject:item atIndex:0];
         NSIndexPath* index = [NSIndexPath indexPathForRow:0 inSection:[self topSection] ? 1 : 0];
         [self.collection_view insertItemsAtIndexPaths:@[index]];
       } completion:^(BOOL finished)
       {
         [self updateRunningTransactions];
       }];
    }
  }
}

- (void)peerTransactionUpdated:(NSNotification*)notification
{
  NSNumber* transaction_id = notification.userInfo[kInfinitTransactionId];
  for (InfinitHomeItem* item in self.data)
  {
    if (item.transaction != nil && [item.transaction.id_ isEqualToNumber:transaction_id])
    {
      [self updateItem:item];
      return;
    }
  }
  // Transaction not in local model.
  InfinitPeerTransaction* peer_transaction =
    [[InfinitPeerTransactionManager sharedInstance] transactionWithId:transaction_id];
  if (!peer_transaction.concerns_device || peer_transaction.archived)
    return;
  InfinitHomeItem* item = [[InfinitHomeItem alloc] initWithTransaction:peer_transaction];
  [self addItem:item];
}

- (void)removeOnboardingView
{
  [self.onboarding_view removeFromSuperview];
  self.onboarding_view = nil;
}

- (void)removeNoActivityView
{
  [self.no_activity_view removeFromSuperview];
  self.no_activity_view = nil;
}

- (void)updateItem:(InfinitHomeItem*)item
{
  @synchronized(self.data)
  {
    if (![self.data containsObject:item])
      return;
    [self.collection_view performBatchUpdates:^
    {
      BOOL concerns_device = item.transaction.concerns_device;
      NSUInteger index = [self.data indexOfObject:item];
      [self.data removeObject:item];
      NSUInteger section = [self topSection] ? 1 : 0;
      [self.collection_view deleteItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:index
                                                                          inSection:section]]];
      if (concerns_device)
      {
        if (self.onboarding_view != nil)
        {
          [self performSelectorOnMainThread:@selector(removeOnboardingView)
                                 withObject:nil
                              waitUntilDone:NO];
        }
        if (self.no_activity_view != nil)
        {
          [self performSelectorOnMainThread:@selector(removeNoActivityView)
                                 withObject:nil
                              waitUntilDone:NO];
        }
        [self.data insertObject:item atIndex:0];
        [self.collection_view insertItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:0
                                                                            inSection:section]]];
      }
    } completion:^(BOOL finished)
    {
      [self updateRunningTransactions];
    }];
  }
}

#pragma mark - User Handling

- (void)userAvatarUpdated:(NSNotification*)notification
{
  NSNumber* user_id = notification.userInfo[@"id"];
  if ([InfinitDeviceManager sharedInstance].other_devices.count > 0 &&
      [[InfinitUserManager sharedInstance].me.id_ isEqualToNumber:user_id])
  {
    // Don't replace device avatars with our own.
    return;
  }
  [self.data enumerateObjectsUsingBlock:^(InfinitHomeItem* item, NSUInteger row, BOOL* stop)
  {
    if (item.transaction && [item.transaction isKindOfClass:InfinitPeerTransaction.class])
    {
      InfinitPeerTransaction* peer_transaction = (InfinitPeerTransaction*)item.transaction;
      if ([peer_transaction.other_user.id_ isEqualToNumber:user_id])
      {
        UIImage* avatar =
          [peer_transaction.other_user.avatar infinit_circularMaskOfSize:_avatar_size];
        [self.round_avatar_cache setObject:avatar forKey:peer_transaction.other_user.id_];
        NSIndexPath* path = [NSIndexPath indexPathForRow:row inSection:[self topSection] ? 1 : 0];
        if (![self.collection_view.indexPathsForVisibleItems containsObject:path])
          return;
        InfinitHomePeerTransactionCell* cell =
        (InfinitHomePeerTransactionCell*)[self.collection_view cellForItemAtIndexPath:path];
        [cell performSelectorOnMainThread:@selector(setAvatar:) withObject:avatar waitUntilDone:NO];
        *stop = YES;
      }
    }
  }];
}

#pragma mark - Gesture Handling

- (IBAction)handleRemoveGesture:(UIGestureRecognizer*)recognizer
{
  CGPoint location = [recognizer locationInView:self.collection_view];
  CGPoint window_location = [self.view convertPoint:location fromView:self.collection_view];

  if (recognizer.state == UIGestureRecognizerStateBegan)
  {
    if (self.cell_image_view)
      return;
    NSIndexPath* index = [self.collection_view indexPathForItemAtPoint:location];
    UICollectionViewCell* cell = [self.collection_view cellForItemAtIndexPath:index];
    if (!cell)
      return;
    if ((![self topSection] && self.data.count > 0 && index.section == 0) ||
        ([self topSection] && self.data.count > 0 && index.section == 1))
    {
      InfinitHomeItem* item = self.data[index.row];
      if (item.transaction != nil && !item.transaction.done)
      {
        cell.transform = CGAffineTransformTranslate(cell.transform, -20.0f, 0.0f);
        [UIView animateWithDuration:0.5f
                              delay:0.0f
             usingSpringWithDamping:0.2f
              initialSpringVelocity:10.0f
                            options:0
                         animations:^
        {
          cell.transform = CGAffineTransformIdentity;
        } completion:^(BOOL finished)
        {
          cell.transform = CGAffineTransformIdentity;
          if (!item.expanded)
          {
            [self.collection_view selectItemAtIndexPath:index
                                               animated:YES
                                         scrollPosition:UICollectionViewScrollPositionNone];
            [self collectionView:self.collection_view didSelectItemAtIndexPath:index];
          }
        }];
        return;
      }
    }
    _moving_cell = cell;
    _touch_offset = UIOffsetMake(location.x - cell.center.x, location.y - cell.center.y);

    UIGraphicsBeginImageContextWithOptions(cell.bounds.size, NO, 0.0f);
    [cell.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage* cell_image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    _cell_image_view = [[UIImageView alloc] initWithImage:cell_image];
    self.cell_image_view.layer.cornerRadius = 3.0f;
    self.cell_image_view.layer.masksToBounds = NO;
    self.cell_image_view.layer.shadowOpacity = 0.3f;
    self.cell_image_view.layer.shadowRadius = 5.0f;
    self.cell_image_view.layer.shadowColor = [UIColor blackColor].CGColor;
    self.cell_image_view.layer.shadowOffset = CGSizeMake(0.0f, 5.0f);
    self.cell_image_view.layer.shadowPath =
      [UIBezierPath bezierPathWithRoundedRect:self.cell_image_view.bounds cornerRadius:3.0f].CGPath;
    [self.cell_image_view setCenter:CGPointMake(window_location.x - self.touch_offset.horizontal,
                                                window_location.y - self.touch_offset.vertical)];
    if (self.dynamic_animator == nil)
      _dynamic_animator = [[UIDynamicAnimator alloc] init];
    else
      [self.dynamic_animator removeAllBehaviors];
    _anchor_behavior = [[UIAttachmentBehavior alloc] initWithItem:self.cell_image_view
                                                 offsetFromCenter:self.touch_offset
                                                 attachedToAnchor:window_location];
    self.anchor_behavior.length = 0.0f;
    [self.dynamic_animator addBehavior:self.anchor_behavior];
    [self.view addSubview:self.cell_image_view];
    cell.alpha = 0.0f;
  }
  else if (recognizer.state == UIGestureRecognizerStateChanged)
  {
    if (self.anchor_behavior)
      self.anchor_behavior.anchorPoint = window_location;
  }
  else if (recognizer.state == UIGestureRecognizerStateEnded)
  {
    if (!self.anchor_behavior)
      return;
    [self.dynamic_animator removeAllBehaviors];
    NSTimeInterval t_diff = CFAbsoluteTimeGetCurrent() - self.last_time;
    CGPoint velocity;
    if ([recognizer isKindOfClass:UIPanGestureRecognizer.class])
    {
      velocity = [(UIPanGestureRecognizer*)recognizer velocityInView:self.view.window];
    }
    else
    {
      velocity = CGPointMake((location.x - self.last_location.x) / t_diff,
                             (location.y - self.last_location.y) / t_diff);
    }
    CGFloat limit = 5.0f;
    BOOL remove_cell =
      location.x < limit || location.x > self.collection_view.bounds.size.width - limit ||
      (ABS(self.moving_cell.center.x - location.x) > 50.0f &&
       ABS(velocity.x) > 0.9f * ABS(velocity.y) && ABS(velocity.x) > 100.0f);
    if (remove_cell)
    {
      UIDynamicItemBehavior* current_behavior =
        [[UIDynamicItemBehavior alloc] initWithItems:@[self.cell_image_view]];
      [current_behavior addLinearVelocity:velocity forItem:self.cell_image_view];
      UIPushBehavior* push_behavior =
        [[UIPushBehavior alloc] initWithItems:@[self.cell_image_view]
                                         mode:UIPushBehaviorModeContinuous];
      push_behavior.magnitude = 1.0f;
      push_behavior.pushDirection = CGVectorMake(velocity.x, velocity.y);
      current_behavior.action = ^
      {
        if (!CGRectIntersectsRect(self.view.window.frame, self.cell_image_view.frame))
        {
          [self.dynamic_animator removeAllBehaviors];
          if ([self.moving_cell isKindOfClass:InfinitHomePeerTransactionCell.class])
          {
            NSIndexPath* index = [self.collection_view indexPathForCell:self.moving_cell];
            [self removeItemAtIndexPath:index];
          }
          else if ([self.moving_cell isKindOfClass:InfinitHomeOnboardingCell.class])
          {
            [self removeOnboardingCell:(InfinitHomeOnboardingCell*)self.moving_cell];
          }
          else if ([self.moving_cell isKindOfClass:InfinitHomeRatingCell.class])
          {
            [self doneRating];
          }
          [self.cell_image_view removeFromSuperview];
          _cell_image_view = nil;
          _anchor_behavior = nil;
        }
      };
      [self.dynamic_animator addBehavior:current_behavior];
      [self.dynamic_animator addBehavior:push_behavior];
    }
    else
    {
      CGPoint final_point = [self.view.window convertPoint:self.moving_cell.center
                                                  fromView:self.collection_view];
      UISnapBehavior* snap_back = [[UISnapBehavior alloc] initWithItem:self.cell_image_view
                                                           snapToPoint:final_point];
      snap_back.action = ^
      {
        if (CGPointEqualToPoint(self.cell_image_view.center, final_point))
        {
          [self.dynamic_animator removeAllBehaviors];
          self.moving_cell.alpha = 1.0f;
          [self.cell_image_view removeFromSuperview];
          _cell_image_view = nil;
          _anchor_behavior = nil;
        }
      };
      [self.dynamic_animator addBehavior:snap_back];
    }
  }
  self.last_time = CFAbsoluteTimeGetCurrent();
  self.last_location = location;
}

- (void)removeItemAtIndexPath:(NSIndexPath*)path
{
  if (path == nil || self.data.count == 0)
    return;
  @synchronized(self.data)
  {
    if (self.data.count == 1)
    {
      InfinitTransaction* transaction = [self.data[path.row] transaction];
      if (transaction != nil && [transaction isKindOfClass:InfinitPeerTransaction.class])
      {
        InfinitPeerTransaction* peer_transaction = (InfinitPeerTransaction*)transaction;
        [[InfinitPeerTransactionManager sharedInstance] archiveTransaction:peer_transaction];
        if (transaction.from_device)
          [[InfinitUploadThumbnailManager sharedInstance] removeThumbnailsForTransaction:peer_transaction];
      }
      [self.data removeAllObjects];
      [self.collection_view reloadData];
      if (![self topSection] && ![self bottomSection])
        [self showNoActivityView];
    }
    else
    {
      [self.collection_view performBatchUpdates:^
      {
        InfinitTransaction* transaction = [self.data[path.row] transaction];
        if (transaction != nil && [transaction isKindOfClass:InfinitPeerTransaction.class])
        {
          InfinitPeerTransaction* peer_transaction = (InfinitPeerTransaction*)transaction;
          [[InfinitPeerTransactionManager sharedInstance] archiveTransaction:peer_transaction];
          if (transaction.from_device)
            [[InfinitUploadThumbnailManager sharedInstance] removeThumbnailsForTransaction:peer_transaction];
        }
        [self.data removeObjectAtIndex:path.row];
        [self.collection_view deleteItemsAtIndexPaths:@[path]];
      } completion:^(BOOL finished)
      {
        [self updateRunningTransactions];
      }];
    }
  }
}

#pragma mark - Cell Protocol

- (void)cellAcceptTapped:(InfinitHomePeerTransactionCell*)sender
{
  NSError* error = nil;
  [[InfinitPeerTransactionManager sharedInstance] acceptTransaction:sender.transaction
                                                          withError:&error];
  if (error && [error.domain isEqualToString:INFINIT_FILE_SYSTEM_ERROR_DOMAIN])
  {
    UIAlertView* alert = nil;
    NSString* message = nil;
    NSString* title = nil;
    if (error.code == InfinitFileSystemErrorNoFreeSpace)
    {
      title = NSLocalizedString(@"Not enough free space!", nil);
      message =
      [NSString stringWithFormat:NSLocalizedString(@"You need %@ of space to accept this transfer.", nil),
       [InfinitDataSize fileSizeStringFrom:sender.transaction.size]];
    }
    else
    {
      title = NSLocalizedString(@"Unable to accept!", nil);
    }
    alert = [[UIAlertView alloc] initWithTitle:title
                                       message:message
                                      delegate:nil
                             cancelButtonTitle:NSLocalizedString(@"OK", nil)
                             otherButtonTitles:nil];
    [alert show];
  }
}

- (void)cellRejectTapped:(InfinitHomePeerTransactionCell*)sender
{
  [[InfinitPeerTransactionManager sharedInstance] rejectTransaction:sender.transaction];
}

- (void)cellPauseTapped:(InfinitHomePeerTransactionCell*)sender
{
  InfinitPeerTransactionManager* manager = [InfinitPeerTransactionManager sharedInstance];
  if (sender.transaction.status == gap_transaction_paused)
    [manager resumeTransaction:sender.transaction];
  else
    [manager pauseTransaction:sender.transaction];
}

- (void)cellCancelTapped:(InfinitHomePeerTransactionCell*)sender
{
  [[InfinitPeerTransactionManager sharedInstance] cancelTransaction:sender.transaction];
}

- (void)cellOpenTapped:(InfinitHomePeerTransactionCell*)sender
{
  InfinitFolderModel* folder =
    [[InfinitDownloadFolderManager sharedInstance] completedFolderForTransactionMetaId:sender.transaction.meta_id];
  if (folder.files.count == 1)
  {
    self.previewing_files = YES;
    InfinitFilePreviewController* preview_controller =
      [InfinitFilePreviewController controllerWithFolder:folder andIndex:0];
    UINavigationController* nav_controller =
      [[UINavigationController alloc] initWithRootViewController:preview_controller];
    [self presentViewController:nav_controller animated:YES completion:nil];
  }
  else if (folder.files.count > 1)
  {
    self.previewing_files = YES;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
      [((InfinitMainSplitViewController_iPad*)self.splitViewController) showViewForFolder:folder];
    }
    else
    {
      [self performSegueWithIdentifier:@"home_files_segue" sender:folder];
    }
  }
}

- (void)cell:(InfinitHomePeerTransactionCell*)sender
openFileTapped:(NSUInteger)file_index
{
  self.previewing_files = YES;
  InfinitFolderModel* folder =
    [[InfinitDownloadFolderManager sharedInstance] completedFolderForTransactionMetaId:sender.transaction.meta_id];
  InfinitFilePreviewController* preview_controller =
    [InfinitFilePreviewController controllerWithFolder:folder andIndex:file_index];
  UINavigationController* nav_controller =
  [[UINavigationController alloc] initWithRootViewController:preview_controller];
  [self presentViewController:nav_controller animated:YES completion:nil];
}

- (void)cellSendTapped:(InfinitHomePeerTransactionCell*)sender
{
  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
  {
    InfinitDownloadFolderManager* manager = [InfinitDownloadFolderManager sharedInstance];
    InfinitFolderModel* folder =
      [manager completedFolderForTransactionMetaId:sender.transaction.meta_id];
    NSArray* files = folder.file_paths;
    [((InfinitMainSplitViewController_iPad*)self.splitViewController) showSendViewForFiles:files];
    [InfinitMetricsManager sendMetric:InfinitUIEventSendRecipientViewOpen
                               method:InfinitUIMethodHomeCard];
  }
  else
  {
    _sending = YES;
    [self performSegueWithIdentifier:@"home_card_to_send_segue" sender:sender];
  }
}

#pragma mark - Onboarding Cell Handling

- (void)removeOnboardingCell:(InfinitHomeOnboardingCell*)cell
{
  @synchronized(self.data)
  {
    NSIndexPath* index = [self.collection_view indexPathForCell:cell];
    [self.collection_view performBatchUpdates:^
    {
      NSUInteger section_count = self.collection_view.numberOfSections;
      switch (cell.type)
      {
        case InfinitHomeOnboardingCellBackground:
          self.background_onboarded = YES;
          break;
        case InfinitHomeOnboardingCellPeerSent:
          self.peer_send_onboarded = YES;
          break;
        case InfinitHomeOnboardingCellGhostSent:
          self.ghost_send_onboarded = YES;
          break;
        case InfinitHomeOnboardingCellSelfSent:
          self.self_send_onboarded = YES;
          break;
        case InfinitHomeOnboardingCellNotifications:
          self.notification_onboarded = YES;
          break;
        case InfinitHomeOnboardingCellSwipe:
          self.swipe_onboarded = YES;
          break;
      }
      if ([self topSection] && index.section == 0)
      {
        [self.onboarding_model removeObjectAtIndex:index.row];
        if (self.onboarding_model.count == 0 && !self.show_rate_us)
        {
          [self.collection_view deleteSections:[NSIndexSet indexSetWithIndex:0]];
          [self updateRunningTransactions];
          if (self.swipe_onboarded && self.notification_onboarded && self.data.count == 0)
            [self showNoActivityView];
        }
        else
        {
          [self.collection_view deleteItemsAtIndexPaths:@[index]];
        }
      }
      else if (!self.swipe_onboarded || !self.notification_onboarded)
      {
        NSUInteger count = 0;
        if (self.swipe_onboarded)
          count += 1;
        if (self.notification_onboarded)
          count += 1;
        if (count != 2)
          [self.collection_view deleteItemsAtIndexPaths:@[index]];
        else
          [self.collection_view deleteSections:[NSIndexSet indexSetWithIndex:index.section]];
      }
      else
      {
        [self.collection_view deleteSections:[NSIndexSet indexSetWithIndex:(section_count - 1)]];
        if (self.onboarding_model.count == 0 && self.data.count == 0)
          [self showNoActivityView];
      }
    } completion:NULL];
  }
}

#pragma mark - Extension Files Handling

- (void)showRecipientsForManagedFiles:(NSString*)uuid
{
  _sending = YES;
  _extension_files_uuid = [uuid copy];
  [self performSegueWithIdentifier:@"home_extension_to_send_segue" sender:self];
}

- (void)showRecipientsForLocalFiles:(NSArray*)files
{
  _sending = YES;
  _extension_internal_files = [files copy];
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(500 * NSEC_PER_MSEC)),
                 dispatch_get_main_queue(), ^
  {
    [self performSegueWithIdentifier:@"home_extension_internal_to_send_segue" sender:self];
  });
}

#pragma mark - Rating Cell Handling

- (void)doneRating
{
  [[InfinitRatingManager sharedInstance] doneRating];
  [self.collection_view performBatchUpdates:^
  {
    _show_rate_us = NO;
    if (self.onboarding_model.count == 0)
    {
      [self.collection_view deleteSections:[NSIndexSet indexSetWithIndex:0]];
    }
    else
    {
      NSArray* indexes = @[[NSIndexPath indexPathForRow:self.onboarding_model.count inSection:0]];
      [self.collection_view deleteItemsAtIndexPaths:indexes];
    }
  } completion:^(BOOL finished)
   {
     [self updateRunningTransactions];
   }];
}

- (void)positiveButtonTapped:(id)sender
{
  if (self.rating_cell == nil)
    return;
  switch (self.rating_cell.state)
  {
    case InfinitRatingCellStateFirst:
      self.rating_cell.state = InfinitRatingCellStateRate;
      break;
    case InfinitRatingCellStateRate:
    {
      [self doneRating];
      [InfinitMetricsManager sendMetric:InfinitUIEventRateFromCard method:InfinitUIMethodYes];
      NSString* itunes_link =
        [kInfinitStoreRatingLink stringByReplacingOccurrencesOfString:@"APP_ID"
                                                           withString:kInfinitAppStoreId];
      if ([InfinitHostDevice iOSVersion] > 8.0)
      {
        itunes_link =
          [kInfinitStoreRatingLinkiOS8 stringByReplacingOccurrencesOfString:@"APP_ID"
                                                                 withString:kInfinitAppStoreId];
      }
      [[UIApplication sharedApplication] openURL:[NSURL URLWithString:itunes_link]];
      break;
    }
    case InfinitRatingCellStateFeedback:
    {
      [self doneRating];
      UINib* nib = [UINib nibWithNibName:NSStringFromClass(InfinitHomeFeedbackViewController.class)
                                  bundle:nil];
      InfinitHomeFeedbackViewController* feedback_controller =
        [[nib instantiateWithOwner:self options:nil] firstObject];
      [self presentViewController:feedback_controller animated:YES completion:nil];
      break;
    }

    default:
      break;
  }
}

- (void)negativeButtonTapped:(id)sender
{
  if (self.rating_cell == nil)
    return;
  switch (self.rating_cell.state)
  {
    case InfinitRatingCellStateFirst:
      self.rating_cell.state = InfinitRatingCellStateFeedback;
      break;

    default:
      [self doneRating];
      [InfinitMetricsManager sendMetric:InfinitUIEventRateFromCard method:InfinitUIMethodNo];
      break;
  }
}

#pragma mark - Status Changed

- (void)statusChangedTo:(BOOL)status
{
  if (status)
    [self refreshContents];
  [super statusChangedTo:status];
}

- (void)prepareForSegue:(UIStoryboardSegue*)segue
                 sender:(id)sender
{
  if ([segue.identifier isEqualToString:@"home_card_to_send_segue"] ||
      [segue.identifier isEqualToString:@"home_extension_to_send_segue"] ||
      [segue.identifier isEqualToString:@"home_extension_internal_to_send_segue"])
  {
    InfinitTabBarController* tab_controller = (InfinitTabBarController*)self.tabBarController;
    [tab_controller setTabBarHidden:YES animated:NO];
    InfinitSendRecipientsController* send_controller =
      (InfinitSendRecipientsController*)segue.destinationViewController;
    if ([segue.identifier isEqualToString:@"home_card_to_send_segue"])
    {
      InfinitHomePeerTransactionCell* cell = (InfinitHomePeerTransactionCell*)sender;
      InfinitFolderModel* folder =
        [[InfinitDownloadFolderManager sharedInstance] completedFolderForTransactionMetaId:cell.transaction.meta_id];
      send_controller.files = folder.file_paths;
    }
    else if ([segue.identifier isEqualToString:@"home_extension_internal_to_send_segue"])
    {
      send_controller.extension_send = YES;
      send_controller.files = self.extension_internal_files;
      _extension_internal_files = nil;
    }
    else
    {
      send_controller.extension_send = YES;
      send_controller.extension_files_uuid = self.extension_files_uuid;
      _extension_files_uuid = nil;
    }
    if (send_controller.extension_send)
    {
      [InfinitMetricsManager sendMetric:InfinitUIEventSendRecipientViewOpen
                                 method:InfinitUIMethodExtensionFiles];
    }
    else
    {
      [InfinitMetricsManager sendMetric:InfinitUIEventSendRecipientViewOpen
                                 method:InfinitUIMethodHomeCard];
    }
    [UIView animateWithDuration:0.3f
                     animations:^
    {
      ((InfinitResizableNavigationBar*)self.navigationController.navigationBar).large = YES;
      [[UIApplication sharedApplication] setStatusBarHidden:YES
                                              withAnimation:UIStatusBarAnimationSlide];
      self.navigationController.navigationBar.barTintColor =
        [InfinitColor colorFromPalette:InfinitPaletteColorSendBlack];
    }];
  }
  else if ([segue.identifier isEqualToString:@"home_files_segue"])
  {
    InfinitFilesMultipleViewController* files_view_controller =
      (InfinitFilesMultipleViewController*)segue.destinationViewController;
    files_view_controller.folder = sender;
    [UIView animateWithDuration:0.3f
                     animations:^
     {
       self.navigationController.navigationBar.barTintColor = [UIColor whiteColor];
       self.navigationController.navigationBar.shadowImage = nil;
     }];
  }
}

#pragma mark - Onboarding

- (BOOL)topSection
{
  return (self.show_rate_us || self.onboarding_model.count > 0);
}

- (BOOL)bottomSection
{
  return (!self.notification_onboarded || !self.swipe_onboarded);
}

- (BOOL)notification_onboarded
{
  return [InfinitApplicationSettings sharedInstance].home_onboarded_notifications;
}

- (void)setNotification_onboarded:(BOOL)notification_onboarded
{
  [InfinitApplicationSettings sharedInstance].home_onboarded_notifications = notification_onboarded;
}

- (BOOL)swipe_onboarded
{
  return [InfinitApplicationSettings sharedInstance].home_onboarded_swipe;
}

- (void)setSwipe_onboarded:(BOOL)swipe_onboarded
{
  [InfinitApplicationSettings sharedInstance].home_onboarded_swipe = swipe_onboarded;
}

- (BOOL)peer_send_onboarded
{
  return [InfinitApplicationSettings sharedInstance].home_onboarded_normal_send;
}

- (void)setPeer_send_onboarded:(BOOL)normal_send_onboarded
{
  [InfinitApplicationSettings sharedInstance].home_onboarded_normal_send = normal_send_onboarded;
}

- (BOOL)ghost_send_onboarded
{
  return [InfinitApplicationSettings sharedInstance].home_onboarded_ghost_send;
}

- (void)setGhost_send_onboarded:(BOOL)ghost_send_onboarded
{
  [InfinitApplicationSettings sharedInstance].home_onboarded_ghost_send = ghost_send_onboarded;
}

- (BOOL)self_send_onboarded
{
  return [InfinitApplicationSettings sharedInstance].home_onboarded_self_send;
}

- (void)setSelf_send_onboarded:(BOOL)self_send_onboarded
{
  [InfinitApplicationSettings sharedInstance].home_onboarded_self_send = self_send_onboarded;
}

- (BOOL)background_onboarded
{
  return [InfinitApplicationSettings sharedInstance].home_onboarded_background;
}

- (void)setBackground_onboarded:(BOOL)background_onboarded
{
  [InfinitApplicationSettings sharedInstance].home_onboarded_background = background_onboarded;
}

@end
