//
//  InfinitFileCollectionViewController.m
//  Infinit
//
//  Created by Michael Dee on 12/22/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import "InfinitFileCollectionViewController.h"
#import "FileGridCell.h"
#import "FileListCell.h"

@interface InfinitFileCollectionViewController ()

@property BOOL listShowing;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *styleBarButton;

@end

@implementation InfinitFileCollectionViewController


- (void)viewDidLoad
{
  [super viewDidLoad];
  _listShowing = YES;
  

//  [self.collectionView registerClass:[FileListCell class] forCellWithReuseIdentifier:@"listCell"];
//  [self.collectionView registerClass:[FileGridCell class] forCellWithReuseIdentifier:@"gridCell"];

  
}

#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView*)collectionView
{
    return 1;
}


- (NSInteger)collectionView:(UICollectionView*)collectionView
     numberOfItemsInSection:(NSInteger)section
{
    return 27;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
  if(_listShowing)
  {
    FileListCell* cell = (FileListCell*)[collectionView dequeueReusableCellWithReuseIdentifier:@"listCell" forIndexPath:indexPath];
    return cell;

  }
  else
  {
    FileGridCell* cell = (FileGridCell*)[collectionView dequeueReusableCellWithReuseIdentifier:@"gridCell" forIndexPath:indexPath];
    return cell;
  }
}

#pragma mark – UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView*)collectionView
                  layout:(UICollectionViewLayout*)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath*)indexPath
{
  if(_listShowing)
  {
    return CGSizeMake(320, 80);
  } else {
    return CGSizeMake(104, 104);
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
  if(_listShowing)
  {
    return 0.0;
  } else {
    return 2.0;
  }
}

- (CGFloat)collectionView:(UICollectionView*)collectionView
                   layout:(UICollectionViewLayout*)collectionViewLayout
minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
  if(_listShowing)
  {
    return 0.0;
  } else {
    return 2.0;
  }
}

#pragma mark <UICollectionViewDelegate>

/*
// Uncomment this method to specify if the specified item should be highlighted during tracking
- (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
	return YES;
}
*/

/*
// Uncomment this method to specify if the specified item should be selected
- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}
*/

/*
// Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
- (BOOL)collectionView:(UICollectionView *)collectionView shouldShowMenuForItemAtIndexPath:(NSIndexPath *)indexPath {
	return NO;
}

- (BOOL)collectionView:(UICollectionView *)collectionView canPerformAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
	return NO;
}

- (void)collectionView:(UICollectionView *)collectionView performAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
	
}
*/
- (IBAction)switchStyleButtonSelected:(id)sender
{
  if(_listShowing)
  {
    _listShowing = NO;
    [_styleBarButton setImage:[UIImage imageNamed:@"icon-list"]];
    [self.collectionView reloadData];
  } else {
    _listShowing = YES;
    [_styleBarButton setImage:[UIImage imageNamed:@"icon-grid"]];
    [self.collectionView reloadData];
  }
}

@end
