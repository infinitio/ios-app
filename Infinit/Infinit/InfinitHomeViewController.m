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

@interface InfinitHomeViewController () <UIGestureRecognizerDelegate>

@property (nonatomic, readonly) NSMutableArray* data;

@end

@implementation InfinitHomeViewController
{
@private
  NSString* _peer_transaction_cell_id;
}

- (void)viewDidLoad
{
  _peer_transaction_cell_id = @"home_peer_transaction_cell";
  [super viewDidLoad];
  self.navigationItem.titleView =
    [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icon-logo-red"]];
  UINib* transaction_cell_nib =
    [UINib nibWithNibName:NSStringFromClass(InfinitHomePeerTransactionCell.class) bundle:nil];
  [self.collectionView registerNib:transaction_cell_nib
        forCellWithReuseIdentifier:_peer_transaction_cell_id];
  UISwipeGestureRecognizer* left_swipe_recognizer =
    [[UISwipeGestureRecognizer alloc] initWithTarget:self
                                              action:@selector(leftSwipeGesture:)];
  left_swipe_recognizer.direction = UISwipeGestureRecognizerDirectionLeft;
  left_swipe_recognizer.delegate = self;
  left_swipe_recognizer.numberOfTouchesRequired = 1;
  UISwipeGestureRecognizer* right_swipe_recognizer =
    [[UISwipeGestureRecognizer alloc] initWithTarget:self
                                              action:@selector(rightSwipeGesture:)];
  right_swipe_recognizer.direction = UISwipeGestureRecognizerDirectionRight;
  right_swipe_recognizer.delegate = self;
  right_swipe_recognizer.numberOfTouchesRequired = 1;
  [self.view addGestureRecognizer:left_swipe_recognizer];
  [self.view addGestureRecognizer:right_swipe_recognizer];
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  [self loadTransactions];
}

- (void)loadTransactions
{
  NSArray* peer_transactions = [[InfinitPeerTransactionManager sharedInstance] transactions];
  if (self.data == nil)
    _data = [NSMutableArray array];
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
}

- (void)viewWillDisappear:(BOOL)animated
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [super viewWillDisappear:animated];
}


#pragma mark - UICollectionViewDataSource

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
    [(InfinitHomePeerTransactionCell*)cell setUpWithTransaction:peer_transaction];
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

- (CGFloat)collectionView:(UICollectionView*)collectionView
                   layout:(UICollectionViewLayout*)collectionViewLayout
minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
  return 0.0f;
}

- (CGFloat)collectionView:(UICollectionView*)collectionView
                   layout:(UICollectionViewLayout*)collectionViewLayout
minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
  return 20.0f;
}

#pragma mark - Transaction Handling

- (void)peerTransactionAdded:(NSNotification*)notification
{
  @synchronized(self.data)
  {
    NSNumber* transaction_id = notification.userInfo[@"id"];
    InfinitPeerTransaction* peer_transaction =
      [[InfinitPeerTransactionManager sharedInstance] transactionWithId:transaction_id];
    InfinitHomeItem* item = [[InfinitHomeItem alloc] initWithTransaction:peer_transaction];
    [self.data insertObject:item atIndex:0];
    NSIndexPath* path = [NSIndexPath indexPathForItem:0 inSection:0];
    [self.collectionView performSelectorOnMainThread:@selector(insertItemsAtIndexPaths:)
                                          withObject:@[path] 
                                       waitUntilDone:NO];
  }
}

- (void)peerTransactionUpdated:(NSNotification*)notification
{
  @synchronized(self.data)
  {
    NSNumber* transaction_id = notification.userInfo[@"id"];
    NSUInteger row = 0;
    for (InfinitHomeItem* item in self.data)
    {
      if (item.transaction != nil && [item.transaction.id_ isEqualToNumber:transaction_id])
      {
        NSIndexPath* path = [NSIndexPath indexPathForItem:row inSection:0];
        [self.collectionView performSelectorOnMainThread:@selector(reloadItemsAtIndexPaths:)
                                              withObject:@[path]
                                           waitUntilDone:NO];
        return;
      }
      row++;
    }
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

@end
