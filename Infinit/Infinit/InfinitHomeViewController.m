//
//  InfinitHomeViewController.m
//  Infinit
//
//  Created by Michael Dee on 12/30/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import "InfinitHomeViewController.h"

#import "InfinitHomeItem.h"
#import "InfinitHomePeerTransactionCell.h"

#import <Gap/InfinitPeerTransactionManager.h>
#import <Gap/InfinitUserManager.h>

@interface InfinitHomeViewController () <UIGestureRecognizerDelegate,
                                         InfinitHomePeerTransactionCellProtocol>

@property (nonatomic, readonly) NSMutableArray* data;

@end

@implementation InfinitHomeViewController
{
@private
  NSString* _peer_transaction_cell_id;

  NSTimer* _progress_timer;
  NSTimeInterval _update_interval;
  NSMutableArray* _running_transactions;
}

- (void)viewDidLoad
{
  _peer_transaction_cell_id = @"home_peer_transaction_cell";
  _update_interval = 1.0f;
  [super viewDidLoad];
  self.navigationItem.titleView =
    [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icon-logo-red"]];
  UINib* transaction_cell_nib =
    [UINib nibWithNibName:NSStringFromClass(InfinitHomePeerTransactionCell.class) bundle:nil];
  [self.collectionView registerNib:transaction_cell_nib
        forCellWithReuseIdentifier:_peer_transaction_cell_id];
//  UISwipeGestureRecognizer* left_swipe_recognizer =
//    [[UISwipeGestureRecognizer alloc] initWithTarget:self
//                                              action:@selector(leftSwipeGesture:)];
//  left_swipe_recognizer.direction = UISwipeGestureRecognizerDirectionLeft;
//  left_swipe_recognizer.delegate = self;
//  left_swipe_recognizer.numberOfTouchesRequired = 1;
//  UISwipeGestureRecognizer* right_swipe_recognizer =
//    [[UISwipeGestureRecognizer alloc] initWithTarget:self
//                                              action:@selector(rightSwipeGesture:)];
//  right_swipe_recognizer.direction = UISwipeGestureRecognizerDirectionRight;
//  right_swipe_recognizer.delegate = self;
//  right_swipe_recognizer.numberOfTouchesRequired = 1;
//  [self.collectionView addGestureRecognizer:left_swipe_recognizer];
//  [self.collectionView addGestureRecognizer:right_swipe_recognizer];
}

- (void)viewWillAppear:(BOOL)animated
{
  [self loadTransactions];
  [super viewWillAppear:animated];
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
    [self.collectionView reloadData];
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
        NSIndexPath* path = [NSIndexPath indexPathForRow:row inSection:0];
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
  NSLog(@"xxx updating progress");
  for (NSIndexPath* path in _running_transactions)
  {
    InfinitHomePeerTransactionCell* cell =
      (InfinitHomePeerTransactionCell*)[self.collectionView cellForItemAtIndexPath:path];
    [cell updateProgressOverDuration:_update_interval];
  }
}

- (void)viewWillDisappear:(BOOL)animated
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [super viewWillDisappear:animated];
  [_progress_timer invalidate];
  _progress_timer = nil;
}

#pragma mark - Collection View Protocol

- (void)scrollViewWillBeginDragging:(UIScrollView*)scrollView
{
  for (InfinitHomePeerTransactionCell* cell in self.collectionView.visibleCells)
  {
    cell.cancel_shown = NO;
  }
}

#pragma mark - Data Source

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView*)collectionView
{
  return 1;
}


- (NSInteger)collectionView:(UICollectionView*)collectionView
     numberOfItemsInSection:(NSInteger)section
{
  return self.data.count;
}

- (UICollectionViewCell*)collectionView:(UICollectionView*)collectionView
                 cellForItemAtIndexPath:(NSIndexPath*)indexPath
{
  UICollectionViewCell* cell = nil;
  InfinitHomeItem* item = self.data[indexPath.row];
  if (item.transaction != nil && [item.transaction isKindOfClass:InfinitPeerTransaction.class])
  {
    InfinitPeerTransaction* peer_transaction = (InfinitPeerTransaction*)item.transaction;
    cell = [self.collectionView dequeueReusableCellWithReuseIdentifier:_peer_transaction_cell_id
                                                          forIndexPath:indexPath];
    [(InfinitHomePeerTransactionCell*)cell setUpWithDelegate:self transaction:peer_transaction];
  }
  return cell;
}

#pragma mark – UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView*)collectionView
                  layout:(UICollectionViewLayout*)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath*)indexPath
{
  CGSize res = CGSizeZero;
  InfinitHomeItem* item = self.data[indexPath.row];
  if (item.transaction != nil && [item.transaction isKindOfClass:InfinitPeerTransaction.class])
  {
    return CGSizeMake(300.0f, 300.0f);
  }
  return res;
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
    [self.collectionView performBatchUpdates:^
    {
      [self.data insertObject:item atIndex:0];
      [self.collectionView insertItemsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]]];
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
      [self performSelectorOnMainThread:@selector(updateItem:) withObject:item waitUntilDone:NO];
      return;
    }
  }
}

- (void)updateItem:(InfinitHomeItem*)item
{
  @synchronized(self.data)
  {
    [self.collectionView performBatchUpdates:^
    {
      [self.data removeObject:item];
      [self.data insertObject:item atIndex:0];
      NSUInteger index = [self.data indexOfObject:item];
      [self.collectionView deleteItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:index
                                                                        inSection:0]]];
      [self.collectionView insertItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:0
                                                                        inSection:0]]];
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
        NSIndexPath* path = [NSIndexPath indexPathForRow:row inSection:0];
        if (![self.collectionView.indexPathsForVisibleItems containsObject:path])
          return;
        InfinitHomePeerTransactionCell* cell =
          (InfinitHomePeerTransactionCell*)[self.collectionView cellForItemAtIndexPath:path];
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
    [self.collectionView deleteItemsAtIndexPaths:@[path]];
  }
}

- (void)leftSwipeGesture:(UISwipeGestureRecognizer*)recognizer
{
  if (recognizer.state == UIGestureRecognizerStateEnded)
  {
    NSIndexPath* path =
      [self.collectionView indexPathForItemAtPoint:[recognizer locationInView:self.collectionView]];
    [self removeItemAtIndexPath:path];
  }
}

- (void)rightSwipeGesture:(UISwipeGestureRecognizer*)recognizer
{
  if (recognizer.state == UIGestureRecognizerStateEnded)
  {
    NSIndexPath* path =
      [self.collectionView indexPathForItemAtPoint:[recognizer locationInView:self.collectionView]];
    [self removeItemAtIndexPath:path];
  }
}

#pragma mark - Cell Protocol

- (void)cellHadCancelTappedForTransaction:(InfinitTransaction*)transaction
{
  if ([transaction isKindOfClass:InfinitPeerTransaction.class])
  {
    InfinitPeerTransaction* peer_transaction = (InfinitPeerTransaction*)transaction;
    [[InfinitPeerTransactionManager sharedInstance] cancelTransaction:peer_transaction];
  }
}

@end
