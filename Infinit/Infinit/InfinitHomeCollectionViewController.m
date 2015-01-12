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
  NSMutableArray* linkTransactions =
    [NSMutableArray arrayWithArray:[[InfinitLinkTransactionManager sharedInstance] transactions]];
  
  NSMutableArray* peerTransactions =
    [[[InfinitPeerTransactionManager sharedInstance] transactions] mutableCopy];
  
//  [[NSNotificationCenter defaultCenter] addObserver:self
//                                           selector:@selector(transactionUpdated:)
//                                               name:INFINIT_PEER_TRANSACTION_STATUS_NOTIFICATION
//                                             object:nil];
//  [[NSNotificationCenter defaultCenter] addObserver:self
//                                           selector:@selector(transactionAdded:)
//                                               name:INFINIT_NEW_PEER_TRANSACTION_NOTIFICATION
//                                             object:nil];
//  [[NSNotificationCenter defaultCenter] addObserver:self
//                                           selector:@selector(newAvatar:)
//                                               name:INFINIT_USER_AVATAR_NOTIFICATION
//                                             object:nil];

  
}


#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView*)collectionView
{
    return 1;
}


- (NSInteger)collectionView:(UICollectionView*)collectionView numberOfItemsInSection:(NSInteger)section
{
    return 10;
}

- (UICollectionViewCell*)collectionView:(UICollectionView*)collectionView cellForItemAtIndexPath:(NSIndexPath*)indexPath
{
  if(indexPath.row == 0)
  {
    HomeLargeCollectionViewCell* cell =
      [collectionView dequeueReusableCellWithReuseIdentifier:@"largeCell"
                                                forIndexPath:indexPath];
    
    cell.notification_label.text = @"Mr. Fox wants to send you 4 files.";
    cell.files_label.text = @"4 files";
    
    // Configure the cell
    
    return cell;
  }
  else
  {
    HomeSmallCollectionViewCell* cell =
      [collectionView dequeueReusableCellWithReuseIdentifier:@"smallCell"
                                                forIndexPath:indexPath];
    cell.notification_label.text = @"Sent 12 photos to Amandine Grey.";
    
    // Configure the cell
    
    return cell;
  }

}

#pragma mark – UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView*)collectionView
                  layout:(UICollectionViewLayout*)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath*)indexPath
{
  if(indexPath.row == 0)
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
