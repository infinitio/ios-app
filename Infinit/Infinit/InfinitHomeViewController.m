//
//  InfinitHomeViewController.m
//  Infinit
//
//  Created by Michael Dee on 12/30/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import "InfinitHomeViewController.h"

#import "InfinitColor.h"
#import "InfinitDownloadFolderManager.h"
#import "InfinitHomeItem.h"
#import "InfinitHomePeerTransactionCell.h"
#import "InfinitHomeFeedbackViewController.h"
#import "InfinitHomeOnboardingCell.h"
#import "InfinitHomeRatingCell.h"
#import "InfinitOfflineOverlay.h"
#import "InfinitRatingManager.h"
#import "InfinitTabBarController.h"

#import <Gap/InfinitDataSize.h>
#import <Gap/InfinitPeerTransactionManager.h>
#import <Gap/InfinitUserManager.h>

@interface InfinitHomeViewController () <InfinitHomePeerTransactionCellProtocol,
                                         UICollectionViewDataSource,
                                         UICollectionViewDelegate,
                                         UICollectionViewDelegateFlowLayout,
                                         UIGestureRecognizerDelegate>

@property (nonatomic, weak) IBOutlet UICollectionView* collection_view;

@property (nonatomic, readonly) NSMutableArray* data;
@property (nonatomic, strong) UIView* onboarding_view;
@property (nonatomic, weak) InfinitHomeRatingCell* rating_cell;
@property (nonatomic, readonly) BOOL show_rate_us;

@end

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

#pragma mark - Init

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
  if (self.current_status)
    [self refreshContents];
  [self.collection_view scrollRectToVisible:CGRectMake(0.0f, 0.0f, 1.0f, 1.0f) animated:NO];
}

- (void)refreshContents
{
  _show_rate_us = [InfinitRatingManager sharedInstance].show_transaction_rating;
  [self loadTransactions];
}

- (void)loadTransactions
{
  @synchronized(self.data)
  {
    NSArray* peer_transactions = [[InfinitPeerTransactionManager sharedInstance] transactions];
    if (self.data == nil)
      _data = [NSMutableArray array];
    else
      [self.data removeAllObjects];
    for (InfinitTransaction* transaction in peer_transactions)
    {
      InfinitHomeItem* item = [[InfinitHomeItem alloc] initWithTransaction:transaction];
      [self.data addObject:item];
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
    [self updateRunningTransactions];
    [self.collection_view reloadData];
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
  CGRect frame =
    CGRectMake(0.0f,
               [UIScreen mainScreen].bounds.size.height - height - self.tabBarController.tabBar.bounds.size.height,
               self.view.bounds.size.width,
               height);
  self.onboarding_view.frame = [self.view convertRect:frame fromView:self.view.superview];
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
        NSIndexPath* path = [NSIndexPath indexPathForRow:row inSection:self.show_rate_us ? 1 : 0];
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
    InfinitHomePeerTransactionCell* cell =
      (InfinitHomePeerTransactionCell*)[self.collection_view cellForItemAtIndexPath:path];
    [cell updateProgressOverDuration:_update_interval];
  }
}

- (void)viewWillDisappear:(BOOL)animated
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [_progress_timer invalidate];
  _progress_timer = nil;
  [super viewWillDisappear:animated];
}

#pragma mark - General

- (void)scrollToTop
{
  [self.collection_view scrollRectToVisible:CGRectMake(0.0f, 0.0f, 1.0f, 1.0f) animated:YES];
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

- (void)setExpanded:(BOOL)expanded forIndexPath:(NSIndexPath*)index_path
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
  [UIView animateWithDuration:0.5f
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
     peer_cell.expanded = item.expanded;
   } completion:^(BOOL finished)
   {
     peer_cell.expanded = item.expanded;
   }];
}

#pragma mark - Data Source

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView*)collectionView
{
  return self.show_rate_us ? 2 : 1;
}


- (NSInteger)collectionView:(UICollectionView*)collectionView
     numberOfItemsInSection:(NSInteger)section
{
  if (self.show_rate_us && section == 0)
    return 1;
  else
    return (self.data.count == 0) ? 2 : self.data.count;
}

- (UICollectionViewCell*)collectionView:(UICollectionView*)collectionView
                 cellForItemAtIndexPath:(NSIndexPath*)indexPath
{
  UICollectionViewCell* res = nil;
  if (self.show_rate_us && indexPath.section == 0)
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
  else if (self.data.count > 0)
  {
    InfinitHomeItem* item = self.data[indexPath.row];
    if (item.transaction != nil && [item.transaction isKindOfClass:InfinitPeerTransaction.class])
    {
      InfinitPeerTransaction* peer_transaction = (InfinitPeerTransaction*)item.transaction;
      InfinitHomePeerTransactionCell* cell =
        [self.collection_view dequeueReusableCellWithReuseIdentifier:_peer_transaction_cell_id
                                                       forIndexPath:indexPath];
      [cell setUpWithDelegate:self transaction:peer_transaction expanded:item.expanded];
      res = cell;
    }
  }
  else
  {
    InfinitHomeOnboardingCell* cell =
      [self.collection_view dequeueReusableCellWithReuseIdentifier:_onboarding_cell_id
                                                     forIndexPath:indexPath];
    NSString* message = nil;
    NSString* fullname = [[[InfinitUserManager sharedInstance] me] fullname];
    NSUInteger lines = 0;
    switch (indexPath.row)
    {
      case 0:
        message =
          NSLocalizedString(@"This is where all your current transfers\n"
                            @"and notifications will be displayed.", nil);
        lines = 2;
        break;
      case 1:
        message = [NSString stringWithFormat:NSLocalizedString(@"Welcome to Infinit, %@!", nil),
                   fullname];
        lines = 1;
        break;

      default:
        break;
    }
    cell.message.numberOfLines = lines;
    cell.message.text = message;
    res = cell;
  }
  return res;
}

#pragma mark – UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView*)collectionView
                  layout:(UICollectionViewLayout*)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath*)indexPath
{
  CGFloat width = [UIScreen mainScreen].bounds.size.width - 26.0f;
  CGFloat height = 101.0f;
  CGFloat file_h = 70.0f + 10.0f;
  CGFloat status_h = 45.0f;
  CGFloat button_h = 46.0f; // Includes line above buttons.
  if (self.show_rate_us && indexPath.section == 0) // Rating
  {
    height = 100.0f;
  }
  else if (self.data.count > 0) // Peer transaction
  {
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
          height += status_h + button_h;
        break;
      case gap_transaction_waiting_accept:
        if (transaction.receivable && expanded)
          height += (transaction.files.count > 3 ? 2 * file_h : file_h) + status_h + button_h;
        else if (transaction.receivable)
          height += button_h;
        else if (transaction.sender.is_self && expanded)
          height += status_h + button_h;
        break;

      case gap_transaction_waiting_data:
      case gap_transaction_connecting:
      case gap_transaction_transferring:
      case gap_transaction_paused:
        if (transaction.to_device && expanded)
          height += (transaction.files.count > 3 ? 2 * file_h : file_h) + status_h + button_h;
        break;

      case gap_transaction_cloud_buffered:
      case gap_transaction_rejected:
      case gap_transaction_finished:
      case gap_transaction_failed:
      case gap_transaction_canceled:
        if (expanded)
          height += status_h;
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
  else // Onboarding
  {
    switch (indexPath.row)
    {
      case 0:
        return CGSizeMake(width, 79.0f);
      case 1:
        return CGSizeMake(width, 63.0f);

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
  return UIEdgeInsetsMake(20.0f, 0.0f, 20.0f, 0.0f);
}

#pragma mark - Transaction Handling

- (void)peerTransactionAdded:(NSNotification*)notification
{
  if (self.onboarding_view != nil)
  {
    [self performSelectorOnMainThread:@selector(removeOnboardingView)
                           withObject:nil
                        waitUntilDone:NO];
    return;
  }
  NSNumber* transaction_id = notification.userInfo[@"id"];
  InfinitPeerTransaction* peer_transaction =
    [[InfinitPeerTransactionManager sharedInstance] transactionWithId:transaction_id];
  InfinitHomeItem* item = [[InfinitHomeItem alloc] initWithTransaction:peer_transaction];
  [self performSelectorOnMainThread:@selector(addItem:) withObject:item waitUntilDone:NO];
}

- (void)addItem:(InfinitHomeItem*)item
{
  @synchronized(self.data)
  {
    [self.collection_view.collectionViewLayout invalidateLayout];
    [self.collection_view performBatchUpdates:^
     {
       [self.data insertObject:item atIndex:0];
       NSIndexPath* index = [NSIndexPath indexPathForRow:0 inSection:self.show_rate_us ? 1 : 0];
       [self.collection_view insertItemsAtIndexPaths:@[index]];
     } completion:^(BOOL finished)
     {
       [self updateRunningTransactions];
     }];
  }
}

- (void)peerTransactionUpdated:(NSNotification*)notification
{
  NSNumber* transaction_id = notification.userInfo[@"id"];
  for (InfinitHomeItem* item in self.data)
  {
    if (item.transaction != nil && [item.transaction.id_ isEqualToNumber:transaction_id])
    {
      if (self.onboarding_view != nil)
      {
        [self performSelectorOnMainThread:@selector(removeOnboardingView)
                               withObject:nil
                            waitUntilDone:NO];
        return;
      }
      [self performSelectorOnMainThread:@selector(updateItem:) withObject:item waitUntilDone:NO];
      return;
    }
  }
}

- (void)removeOnboardingView
{
  [self.onboarding_view removeFromSuperview];
  self.onboarding_view = nil;
  [self loadTransactions];
}

- (void)updateItem:(InfinitHomeItem*)item
{
  @synchronized(self.data)
  {
    [self.collection_view performBatchUpdates:^
    {
      NSUInteger index = [self.data indexOfObject:item];
      [self.data removeObject:item];
      [self.data insertObject:item atIndex:0];
      NSUInteger section = self.show_rate_us ? 1 : 0;
      [self.collection_view deleteItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:index
                                                                         inSection:section]]];
      [self.collection_view insertItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:0
                                                                        inSection:section]]];
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
  NSUInteger row = 0;
  for (InfinitHomeItem* item in self.data)
  {
    if (item.transaction != nil && [item.transaction isKindOfClass:InfinitPeerTransaction.class])
    {
      InfinitPeerTransaction* peer_transaction = (InfinitPeerTransaction*)item.transaction;
      if ([peer_transaction.other_user.id_ isEqualToNumber:user_id])
      {
        NSIndexPath* path = [NSIndexPath indexPathForRow:row inSection:self.show_rate_us ? 1 : 0];
        if (![self.collection_view.indexPathsForVisibleItems containsObject:path])
          return;
        InfinitHomePeerTransactionCell* cell =
          (InfinitHomePeerTransactionCell*)[self.collection_view cellForItemAtIndexPath:path];
        [cell performSelectorOnMainThread:@selector(updateAvatar) withObject:nil waitUntilDone:NO];
      }
    }
    row++;
  }
}

#pragma mark - Gesture Handling

- (void)removeItemAtIndexPath:(NSIndexPath*)path
{
  if (path == nil)
    return;
  @synchronized(self.data)
  {
    [self.data removeObjectAtIndex:path.row];
    [self.collection_view deleteItemsAtIndexPaths:@[path]];
  }
}

- (void)leftSwipeGesture:(UISwipeGestureRecognizer*)recognizer
{
  if (recognizer.state == UIGestureRecognizerStateEnded)
  {
    NSIndexPath* path =
      [self.collection_view indexPathForItemAtPoint:[recognizer locationInView:self.collection_view]];
    [self removeItemAtIndexPath:path];
  }
}

- (void)rightSwipeGesture:(UISwipeGestureRecognizer*)recognizer
{
  if (recognizer.state == UIGestureRecognizerStateEnded)
  {
    NSIndexPath* path =
      [self.collection_view indexPathForItemAtPoint:[recognizer locationInView:self.collection_view]];
    [self removeItemAtIndexPath:path];
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
  // XXX pause/resume
}

- (void)cellCancelTapped:(InfinitHomePeerTransactionCell*)sender
{
  [[InfinitPeerTransactionManager sharedInstance] cancelTransaction:sender.transaction];
}

- (void)cellOpenTapped:(InfinitHomePeerTransactionCell*)sender
{
  InfinitTabBarController* tab_controller = (InfinitTabBarController*)self.tabBarController;
  InfinitFolderModel* folder =
    [[InfinitDownloadFolderManager sharedInstance] completedFolderForTransactionMetaId:sender.transaction.meta_id];
  if (folder != nil)
    [tab_controller showFilesScreenForFolder:folder];
}

- (void)cellSendTapped:(InfinitHomePeerTransactionCell*)sender
{
}

#pragma mark - Rating Cell Handling

- (void)doneRating
{
  [[InfinitRatingManager sharedInstance] doneRating];
  [self.collection_view performBatchUpdates:^
  {
    _show_rate_us = NO;
    [self.collection_view deleteSections:[NSIndexSet indexSetWithIndex:0]];
  } completion:nil];
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
      NSString* itunes_link = @"https://itunes.apple.com/us/app/apple-store/id955849852";
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

@end
