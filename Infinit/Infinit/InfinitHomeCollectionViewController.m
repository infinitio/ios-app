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

@interface InfinitHomeCollectionViewController ()

@end

@implementation InfinitHomeCollectionViewController

- (void)viewDidLoad
{
  [super viewDidLoad];
  self.navigationItem.titleView =
    [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icon-logo-red"]];
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
      [collectionView dequeueReusableCellWithReuseIdentifier:@"largeCell" forIndexPath:indexPath];
    
    // Configure the cell
    
    return cell;
  } else {
    HomeSmallCollectionViewCell* cell =
      [collectionView dequeueReusableCellWithReuseIdentifier:@"smallCell" forIndexPath:indexPath];
    
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
    return CGSizeMake(320, 350);
  }
  else
  {
    return CGSizeMake(320, 61);
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

#pragma mark <UICollectionViewDelegate>



@end
