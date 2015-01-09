//
//  InfinitHomeCollectionViewController.m
//  Infinit
//
//  Created by Michael Dee on 12/30/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import "InfinitHomeCollectionViewController.h"

#import "HomeSmallCollectionViewCell.h"
#import "HomeLargeCollectionViewCell.h"

#import <Gap/InfinitLinkTransactionManager.h>
#import <Gap/InfinitPeerTransactionManager.h>
#import <Gap/InfinitUserManager.h>



@interface InfinitHomeCollectionViewController ()

@end

@implementation InfinitHomeCollectionViewController
{
  NSMutableArray* _peer_transactions;
  NSMutableArray* _link_transactions;

}


- (void)viewDidLoad
{
  [super viewDidLoad];
  self.navigationItem.titleView =
    [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icon-logo-red"]];
  
  [self loadTransactions];
}

- (void)loadTransactions
{
  //Load them and display current ones in the right fashion.
  _link_transactions =
    [NSMutableArray arrayWithArray:[[InfinitLinkTransactionManager sharedInstance] transactions]];
  
  _peer_transactions =
    [[[InfinitPeerTransactionManager sharedInstance] transactions] mutableCopy];
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(transactionUpdated:)
                                               name:INFINIT_PEER_TRANSACTION_STATUS_NOTIFICATION
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(transactionAdded:)
                                               name:INFINIT_NEW_PEER_TRANSACTION_NOTIFICATION
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(newAvatar:)
                                               name:INFINIT_USER_AVATAR_NOTIFICATION
                                             object:nil];
  
  
}

- (void)transactionUpdated:(NSNotification*)notification
{
  NSNumber* id_ = notification.userInfo[@"id"];
  InfinitPeerTransaction* new_transaction =
    [[InfinitPeerTransactionManager sharedInstance] transactionWithId:id_];
  
  //Handling for peer for now.
  NSInteger index = 0;
  
  @synchronized(_peer_transactions)
  {
    for (InfinitPeerTransaction* transaction in _peer_transactions)
    {
      if ([transaction.id_ isEqual:notification.userInfo[@"id"]])
      {
        
        break;
      }
      index++;
    }
    
    InfinitPeerTransaction* old_transaction = _peer_transactions[index];
    
    
    if(old_transaction.status != new_transaction.status)
    {
      [_peer_transactions replaceObjectAtIndex:index withObject:new_transaction];
      [self.collectionView reloadData];
      [self.collectionViewLayout invalidateLayout];
    }
    else
    {
      [_peer_transactions replaceObjectAtIndex:index withObject:new_transaction];
    }
  }
}

-(void)transactionAdded:(NSNotification*)notification
{
  
  NSNumber* id_ = notification.userInfo[@"id"];
  InfinitPeerTransaction* transaction =
  [[InfinitPeerTransactionManager sharedInstance] transactionWithId:id_];
  
  
  [_peer_transactions insertObject:transaction atIndex:0];

  
  [self.collectionView reloadData];
  [self.collectionViewLayout invalidateLayout];
  
//  [self.collectionView insertItemsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]]];
  
  
}

-(void)newAvatar:(NSNotification*)notification
{
  NSNumber* user_id = notification.userInfo[@"id"];
  InfinitUser* user = [[InfinitUserManager sharedInstance] userWithId:user_id];
  NSUInteger indexes[_peer_transactions.count];
  NSUInteger size = 0;
  NSUInteger row = 0;
  @synchronized(_peer_transactions)
  {
    for (InfinitPeerTransaction* transaction in _peer_transactions)
    {
      if ([transaction.other_user isEqual:user])
      {
        indexes[++size] = row;
      }
      row++;
    }
    if (size > 0)
    {
      NSIndexPath* index_path = [NSIndexPath indexPathWithIndexes:indexes length:size];
      [self.collectionView reloadItemsAtIndexPaths:@[index_path]];
    }
  }
}




#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView*)collectionView
{
    return 1;
}


- (NSInteger)collectionView:(UICollectionView*)collectionView numberOfItemsInSection:(NSInteger)section
{
    return _peer_transactions.count;
}

- (UICollectionViewCell*)collectionView:(UICollectionView*)collectionView cellForItemAtIndexPath:(NSIndexPath*)indexPath
{
  InfinitPeerTransaction* peer_transaction = _peer_transactions[indexPath.row];
  if(peer_transaction.receivable)
  {
    HomeLargeCollectionViewCell* cell =
    [collectionView dequeueReusableCellWithReuseIdentifier:@"largeCell"
                                              forIndexPath:indexPath];

    [cell setUpWithTransaction:peer_transaction];

    cell.accept_button.tag = indexPath.row;
    [cell.accept_button addTarget:self action:@selector(acceptTransaction:)
                 forControlEvents:UIControlEventTouchUpInside];
    
    cell.cancel_button.tag = indexPath.row;
    [cell.cancel_button addTarget:self action:@selector(cancelTransaction:)
                 forControlEvents:UIControlEventTouchUpInside];
    
    
    return cell;
  }
  else
  {
    HomeSmallCollectionViewCell* cell =
      [collectionView dequeueReusableCellWithReuseIdentifier:@"smallCell"
                                                forIndexPath:indexPath];

    [cell setUpWithTransaction:peer_transaction];
    
    return cell;
  }
}

- (void)acceptTransaction:(UIButton*)sender
{
  
  InfinitPeerTransaction* peer_transaction = _peer_transactions[sender.tag];
  [[InfinitPeerTransactionManager sharedInstance] acceptTransaction:peer_transaction];
  
}

- (void)cancelTransaction:(UIButton*)sender
{
  
  InfinitPeerTransaction* peer_transaction = _peer_transactions[sender.tag];
  [[InfinitPeerTransactionManager sharedInstance] cancelTransaction:peer_transaction];
  
}

#pragma mark – UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView*)collectionView
                  layout:(UICollectionViewLayout*)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath*)indexPath
{
  InfinitPeerTransaction* peer_transaction = _peer_transactions[indexPath.row];

  if(peer_transaction.receivable)
  {
    return CGSizeMake(self.view.frame.size.width, self.view.frame.size.width * 1.09375);
  }
  else
  {
    return CGSizeMake(self.view.frame.size.width, 61);
  }
}

- (UIEdgeInsets)collectionView:(UICollectionView*)collectionView
                        layout:(UICollectionViewLayout*)collectionViewLayout
        insetForSectionAtIndex:(NSInteger)section
{
  return UIEdgeInsetsMake(0, 0, 0, 0);
}

- (CGFloat)collectionView:(UICollectionView*)collectionView
                   layout:(UICollectionViewLayout*)collectionViewLayout
minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
  return 0.0;
}

- (CGFloat)collectionView:(UICollectionView*)collectionView
                   layout:(UICollectionViewLayout*)collectionViewLayout
minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
  return 2.0;
}

@end
