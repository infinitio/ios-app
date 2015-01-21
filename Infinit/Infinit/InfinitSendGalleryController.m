//
//  InfinitSendGalleryController.m
//  Infinit
//
//  Created by Michael Dee on 12/17/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import "InfinitSendGalleryController.h"

#import "InfinitSendGalleryCell.h"
#import "InfinitSendRecipientsController.h"
#import "InfinitTabBarController.h"

#import "ALAsset+Date.h"

#import <Gap/InfinitTemporaryFileManager.h>

@import AssetsLibrary;
@import AVFoundation;
@import Photos;

@interface InfinitSendGalleryController ()

@property (nonatomic, strong) NSArray* assets;
@property (nonatomic, weak) IBOutlet UIBarButtonItem* next_button;

@end

@implementation InfinitSendGalleryController
{
@private
  NSString* _cell_identifier;
  UITapGestureRecognizer* _nav_bar_tap;
}

- (id)initWithCoder:(NSCoder*)aDecoder
{
  if (self = [super initWithCoder:aDecoder])
  {
    _cell_identifier = @"gallery_cell";
    _assets = nil;
    _nav_bar_tap = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                           action:@selector(navBarTapped)];
  }
  return self;
}

- (BOOL)prefersStatusBarHidden
{
  return YES;
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation
{
  return UIStatusBarAnimationSlide;
}

- (void)viewDidLoad
{
  self.collectionView.alwaysBounceVertical = YES;
  [super viewDidLoad];
  self.collectionView.allowsMultipleSelection = YES;

  self.navigationController.navigationBar.clipsToBounds = YES;
  NSDictionary* nav_bar_attrs = @{NSFontAttributeName: [UIFont fontWithName:@"SourceSansPro-Bold"
                                                                       size:17.0f],
                                  NSForegroundColorAttributeName: [UIColor whiteColor]};
  NSDictionary* clear_attrs = @{NSForegroundColorAttributeName: [UIColor clearColor]};
  [self.navigationController.navigationBar setTitleTextAttributes:nav_bar_attrs];
  [self.next_button setTitleTextAttributes:nav_bar_attrs forState:UIControlStateNormal];
  [self.next_button setTitleTextAttributes:clear_attrs forState:UIControlStateDisabled];
}

- (void)viewWillAppear:(BOOL)animated
{
  if (self.assets == nil)
    [self loadAssets];
  [self setNextButtonTitle];
  if (self.collectionView.indexPathsForSelectedItems.count == 0)
    self.next_button.enabled = NO;
  else
    self.next_button.enabled = YES;
  self.collectionView.contentOffset = CGPointMake(0.0f, 0.0f - self.collectionView.contentInset.top);
  [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];
  [self.collectionViewLayout invalidateLayout];
  [self.navigationController.navigationBar.subviews[0] setUserInteractionEnabled:YES];
  [self.navigationController.navigationBar.subviews[0] addGestureRecognizer:_nav_bar_tap];
}

- (void)navBarTapped
{
  [self.collectionView scrollRectToVisible:CGRectMake(0.0f, 0.0f, 1.0f, 1.0f) animated:YES];
}

- (void)viewWillDisappear:(BOOL)animated
{
  [self.navigationController.navigationBar.subviews[0] removeGestureRecognizer:_nav_bar_tap];
  [super viewWillDisappear:animated];
}

- (void)loadAssets
{
  if ([PHAsset class])
  {
    PHFetchOptions* options = [[PHFetchOptions alloc] init];
    options.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate"
                                                              ascending:NO]];
    PHFetchResult* assets = [PHAsset fetchAssetsWithOptions:options];
    __block NSMutableArray* temp_assets = [NSMutableArray array];
    __block NSMutableArray* except_list = [NSMutableArray array];
    [assets enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL* stop)
    {
      [temp_assets addObject:obj];
    }];
    PHFetchResult* collections =
      [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum
                                               subtype:PHAssetCollectionSubtypeAlbumCloudShared
                                               options:nil];
    [collections enumerateObjectsUsingBlock:^(PHAssetCollection* collection,
                                              NSUInteger idx,
                                              BOOL*stop)
    {
      PHFetchResult* assets2 = [PHAsset fetchAssetsInAssetCollection:collection options:options];
      [assets2 enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL* stop)
      {
        [except_list addObject:obj];
      }];
    }];
    [temp_assets removeObjectsInArray:except_list];
    self.assets = [temp_assets copy];
  }
  else
  {
    __block NSMutableArray* temp_assets = [NSMutableArray array];
    [[self defaultAssetsLibrary] enumerateGroupsWithTypes:ALAssetsGroupAll
                                               usingBlock:^(ALAssetsGroup* group, BOOL* stop)
    {

      [group enumerateAssetsUsingBlock:^(ALAsset* result, NSUInteger index, BOOL* stop)
      {
        if (result)
        {
          [temp_assets addObject:result];
        }
      }];
      NSSortDescriptor* sort = [NSSortDescriptor sortDescriptorWithKey:@"date" ascending:NO];
      self.assets = [temp_assets sortedArrayUsingDescriptors:@[sort]];
      [self.collectionView performSelectorOnMainThread:@selector(reloadData)
                                            withObject:nil
                                         waitUntilDone:NO];
    } failureBlock:^(NSError* error)
    {
      NSLog(@"Error loading images %@", error);
    }];
  }
}

#pragma mark - General

- (void)resetView
{
  self.assets = nil;
  for (NSIndexPath* path in self.collectionView.indexPathsForSelectedItems)
    [self.collectionView deselectItemAtIndexPath:path animated:NO];
}

#pragma mark - AssetsLibrary Call

- (ALAssetsLibrary*)defaultAssetsLibrary
{
  static dispatch_once_t pred = 0;
  static ALAssetsLibrary* library = nil;
  dispatch_once(&pred, ^{
    library = [[ALAssetsLibrary alloc] init];
  });
  return library;
}

#pragma mark - UICollectionView Datasource

- (NSInteger)collectionView:(UICollectionView*)collectionView
     numberOfItemsInSection:(NSInteger)section
{
  return self.assets.count;
}

- (PHCachingImageManager*)cachingManager
{
  static dispatch_once_t pred = 0;
  static PHCachingImageManager* res = nil;
  dispatch_once(&pred, ^{
    res = [[PHCachingImageManager alloc] init];
  });
  return res;
}

- (UICollectionViewCell*)collectionView:(UICollectionView*)collectionView
                 cellForItemAtIndexPath:(NSIndexPath*)indexPath
{
  InfinitSendGalleryCell* cell =
    [collectionView dequeueReusableCellWithReuseIdentifier:_cell_identifier
                                              forIndexPath:indexPath];

  if ([PHAsset class])
  {
    NSInteger current_tag = cell.tag + 1;
    cell.tag = current_tag;
    PHAsset* asset = self.assets[indexPath.row];
    CGSize size = [self collectionView:self.collectionView
                                layout:self.collectionViewLayout
                sizeForItemAtIndexPath:indexPath];
    [[self cachingManager] requestImageForAsset:asset
                                     targetSize:size
                                    contentMode:PHImageContentModeAspectFill
                                        options:nil
                                  resultHandler:^(UIImage* result, NSDictionary* info)
     {
       if (cell.tag == current_tag)
         cell.image_view.image = result;
     }];
    if (asset.mediaType == PHAssetMediaTypeVideo)
    {
      NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
      formatter.dateFormat = @"m:ss";
      cell.duration_label.text =
        [formatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:asset.duration]];
    }
  }
  else
  {
    ALAsset* asset = self.assets[indexPath.row];

    if ([asset valueForProperty:ALAssetPropertyType] == ALAssetTypeVideo)
    {
      if ([asset valueForProperty:ALAssetPropertyDuration] != ALErrorInvalidProperty)
      {
        NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"m:ss";
        NSTimeInterval duration = [[asset valueForProperty:ALAssetPropertyDuration] doubleValue];
        cell.duration_label.text =
          [formatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:duration]];
      }
      cell.image_view.image = [UIImage imageWithCGImage:asset.thumbnail
                                                  scale:1.0f
                                            orientation:UIImageOrientationUp];
    }
    else if ([asset valueForProperty:ALAssetPropertyType] == ALAssetTypePhoto)
    {
      cell.image_view.image = [UIImage imageWithCGImage:asset.thumbnail
                                                  scale:1.0f
                                            orientation:UIImageOrientationUp];
    }
  }
  if ([self.collectionView.indexPathsForSelectedItems containsObject:indexPath])
    cell.selected = YES;
  else
    cell.selected = NO;
  return cell;
}

#pragma mark – UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView*)collectionView
                  layout:(UICollectionViewLayout*)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath*)indexPath
{
  return CGSizeMake(floor(self.view.bounds.size.width / 3.0f) - 4.0f,
                    floor(self.view.bounds.size.width / 3.0f) - 4.0f);
}

# pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView*)collectionView
didSelectItemAtIndexPath:(NSIndexPath*)indexPath
{
  [self collectionView:collectionView setSelected:YES atIndexPath:indexPath withAnimation:YES];
}

- (void)collectionView:(UICollectionView*)collectionView
didDeselectItemAtIndexPath:(NSIndexPath*)indexPath
{
  [self collectionView:collectionView setSelected:NO atIndexPath:indexPath withAnimation:YES];
}

- (void)collectionView:(UICollectionView*)collectionView
           setSelected:(BOOL)selected
           atIndexPath:(NSIndexPath*)indexPath
         withAnimation:(BOOL)animate
{
  InfinitSendGalleryCell* cell =
    (InfinitSendGalleryCell*)[collectionView cellForItemAtIndexPath:indexPath];
  if (animate)
  {
    [UIView animateWithDuration:0.1f
                          delay:0.0f
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^
     {
       cell.transform = CGAffineTransformMakeScale(0.9f, 0.9f);
       [cell.contentView layoutIfNeeded];
     } completion:^(BOOL finished)
     {
       [UIView animateWithDuration:0.5f
                             delay:0.0f
            usingSpringWithDamping:0.3f
             initialSpringVelocity:10.0f
                           options:UIViewAnimationOptionCurveEaseInOut
                        animations:^
        {
          cell.transform = CGAffineTransformIdentity;
          [cell.contentView layoutIfNeeded];
        } completion:^(BOOL finished)
        {
          if (!finished)
          {
            cell.transform = CGAffineTransformIdentity;
          }
        }];
     }];
  }
  if (self.collectionView.indexPathsForSelectedItems.count == 0)
    self.next_button.enabled = NO;
  else
    self.next_button.enabled = YES;
  [self setNextButtonTitle];
}

- (IBAction)backButtonTapped:(id)sender
{
  [(InfinitTabBarController*)self.tabBarController lastSelectedIndex];
}

- (void)prepareForSegue:(UIStoryboardSegue*)segue sender:(id)sender
{
  if([segue.identifier isEqualToString:@"send_to_segue"])
  {
    NSMutableArray* assets = [NSMutableArray array];
    for (NSIndexPath* path in self.collectionView.indexPathsForSelectedItems)
    {
      id asset = self.assets[path.row];
      [assets addObject:asset];
    }
    InfinitSendRecipientsController* view_controller =
      (InfinitSendRecipientsController*)segue.destinationViewController;
    view_controller.assets = assets;
  }
}

- (void)setNextButtonTitle
{
  NSNumber* count = @(self.collectionView.indexPathsForSelectedItems.count);
  NSMutableString* next_str = [NSMutableString stringWithString:NSLocalizedString(@"Next", nil)];
  if (count.unsignedIntegerValue > 0)
    [next_str appendFormat:@" (%@)", count];
  [UIView performWithoutAnimation:^
  {
    self.next_button.title = next_str;
  }];
}

@end
