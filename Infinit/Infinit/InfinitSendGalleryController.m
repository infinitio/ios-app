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

@interface InfinitSendGalleryController () <UICollectionViewDataSource,
                                            UICollectionViewDelegate,
                                            UICollectionViewDelegateFlowLayout>

@property (nonatomic, strong) NSArray* assets;
@property (nonatomic, weak) IBOutlet UICollectionView* collection_view;
@property (nonatomic, weak) IBOutlet UIButton* next_button;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint* next_constraint;
@property (nonatomic, strong) PHCachingImageManager* image_caching_manager;

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
    self.dark = YES;
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
  _image_caching_manager = [[PHCachingImageManager alloc] init];
  self.collection_view.alwaysBounceVertical = YES;
  [super viewDidLoad];
  self.collection_view.allowsMultipleSelection = YES;

  UINib* cell_nib = [UINib nibWithNibName:NSStringFromClass(InfinitSendGalleryCell.class)
                                   bundle:nil];
  [self.collection_view registerNib:cell_nib forCellWithReuseIdentifier:_cell_identifier];

  [self.navigationController.navigationBar setBackgroundImage:[[UIImage alloc] init]
                                                forBarMetrics:UIBarMetricsDefault];
  self.navigationController.navigationBar.shadowImage = [[UIImage alloc] init];
  NSDictionary* nav_bar_attrs = @{NSFontAttributeName: [UIFont fontWithName:@"SourceSansPro-Bold"
                                                                       size:17.0f],
                                  NSForegroundColorAttributeName: [UIColor whiteColor]};
  [self.navigationController.navigationBar setTitleTextAttributes:nav_bar_attrs];
  self.next_button.titleEdgeInsets =
    UIEdgeInsetsMake(0.0f,
                     - self.next_button.imageView.frame.size.width,
                     0.0f,
                     self.next_button.imageView.frame.size.width);
  self.next_button.imageEdgeInsets =
    UIEdgeInsetsMake(0.0f,
                     self.next_button.titleLabel.frame.size.width + 10.0f,
                     0.0f,
                     - (self.next_button.titleLabel.frame.size.width + 10.0f));
}

- (void)viewWillAppear:(BOOL)animated
{
  if (self.assets == nil)
    [self loadAssets];
  [self configureNextButton];
  self.collection_view.contentOffset =
    CGPointMake(0.0f, 0.0f - self.collection_view.contentInset.top);
  [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];
  [self.collection_view.collectionViewLayout invalidateLayout];
  [self.navigationController.navigationBar.subviews[0] setUserInteractionEnabled:YES];
  [self.navigationController.navigationBar.subviews[0] addGestureRecognizer:_nav_bar_tap];
  [self.image_caching_manager stopCachingImagesForAllAssets];
}

- (void)navBarTapped
{
  [self.collection_view scrollRectToVisible:CGRectMake(0.0f, 0.0f, 1.0f, 1.0f) animated:YES];
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
    [self.collection_view reloadData];
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
      [self.collection_view performSelectorOnMainThread:@selector(reloadData)
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
  for (NSIndexPath* path in self.collection_view.indexPathsForSelectedItems)
    [self.collection_view deselectItemAtIndexPath:path animated:NO];
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
    CGSize size = [self collectionView:self.collection_view
                                layout:self.collection_view.collectionViewLayout
                sizeForItemAtIndexPath:indexPath];
    [self.image_caching_manager requestImageForAsset:asset
                                          targetSize:size
                                         contentMode:PHImageContentModeAspectFill
                                             options:nil
                                       resultHandler:^(UIImage* result,
                                                       NSDictionary* info)
     {
       if (cell.tag == current_tag)
         cell.thumbnail_view.image = result;
     }];
    if (asset.mediaType == PHAssetMediaTypeVideo)
    {
      cell.video_duration = asset.duration;
    }
  }
  else
  {
    ALAsset* asset = self.assets[indexPath.row];

    if ([asset valueForProperty:ALAssetPropertyType] == ALAssetTypeVideo)
    {
      if ([asset valueForProperty:ALAssetPropertyDuration] != ALErrorInvalidProperty)
      {
        NSTimeInterval duration = [[asset valueForProperty:ALAssetPropertyDuration] doubleValue];
        cell.video_duration = duration;
      }
      cell.thumbnail_view.image = [UIImage imageWithCGImage:asset.thumbnail
                                                  scale:1.0f
                                            orientation:UIImageOrientationUp];
    }
    else if ([asset valueForProperty:ALAssetPropertyType] == ALAssetTypePhoto)
    {
      cell.thumbnail_view.image = [UIImage imageWithCGImage:asset.thumbnail
                                                      scale:1.0f
                                                orientation:UIImageOrientationUp];
    }
  }
  if ([self.collection_view.indexPathsForSelectedItems containsObject:indexPath])
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
  [self configureNextButton];
}

- (IBAction)backButtonTapped:(id)sender
{
  // WORKAROUND: For some reason the view is resized when transitioning back which makes the next
  // button show.
  self.next_constraint.constant = - 3.0f * self.next_button.bounds.size.height;
  [(InfinitTabBarController*)self.tabBarController lastSelectedIndex];
}

- (void)prepareForSegue:(UIStoryboardSegue*)segue sender:(id)sender
{
  if ([segue.identifier isEqualToString:@"send_to_segue"])
  {
    NSMutableArray* assets = [NSMutableArray array];
    for (NSIndexPath* path in self.collection_view.indexPathsForSelectedItems)
    {
      id asset = self.assets[path.row];
      [assets addObject:asset];
    }
    InfinitSendRecipientsController* view_controller =
      (InfinitSendRecipientsController*)segue.destinationViewController;
    view_controller.assets = assets;
  }
}

- (void)configureNextButton
{
  CGFloat v_constraint = 0.0f;
  if (self.collection_view.indexPathsForSelectedItems.count == 0)
  {
    self.next_button.enabled = NO;
    v_constraint = -self.next_button.bounds.size.height;
  }
  else
  {
    self.next_button.enabled = YES;
    v_constraint = 0.0f;
  }
  if (self.next_constraint.constant == v_constraint)
    return;
  [UIView animateWithDuration:0.3f
                        delay:0.0f
                      options:UIViewAnimationOptionCurveEaseInOut
                   animations:^
   {
     self.next_constraint.constant = v_constraint;
     [self.view layoutIfNeeded];
   } completion:^(BOOL finished)
   {
     if (!finished)
       self.next_constraint.constant = v_constraint;
   }];
}

#pragma mark - Offline Overlay

- (NSArray*)verticalConstraints
{
  NSDictionary* views = @{@"overlay": self.offline_overlay,
                          @"button": self.next_button};
  return [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[overlay][button]"
                                                 options:0 
                                                 metrics:nil
                                                   views:views];
}

- (void)filesButtonTapped
{
  // WORKAROUND: For some reason the view is resized when transitioning back which makes the next
  // button show.
  self.next_constraint.constant = - 3.0f * self.next_button.bounds.size.height;
}

@end
